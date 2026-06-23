import SwiftData
import Foundation

@Model
final class ExpenseAccount: Identifiable {
    var uuid: UUID = UUID()
    var name: String = ""
    var iconName: String = ""
    var isDefault: Bool = false
    var sortOrder: Int = 0
    // Nullify (not cascade): a direct delete leaves expenses intact with a nil
    // account; deleteSafely() reassigns to the default account before delete.
    @Relationship(deleteRule: .nullify, inverse: \Expense.account) var expenses: [Expense]?
    
    /// Create Account based on draft
    init(from draft: AccountDraft) {
        self.name = draft.name
        self.iconName = draft.iconName
        self.isDefault = draft.isDefault
        self.sortOrder = draft.sortOrder
    }
    
    /// Update based on draft
    func update(from draft: AccountDraft) {
        self.name = draft.name
        self.iconName = draft.iconName
        self.isDefault = draft.isDefault
        self.sortOrder = draft.sortOrder
    }
}


extension ExpenseAccount {
    static func getDefault(with context: ModelContext) -> ExpenseAccount {
        let descriptor = FetchDescriptor<ExpenseAccount>(predicate: #Predicate { $0.isDefault })
        if let defaultAccount = try? context.fetch(descriptor).first {
            return defaultAccount
        }
        let defaultAccount = createDefault()
        context.insert(defaultAccount)
        return defaultAccount
    }
    
    static func createDefault() -> ExpenseAccount {
        return ExpenseAccount(from: AccountDraft(name: String(localized: "Default"), iconName: "tag", isDefault: true))
    }
    
    static func activateAccounts(with context: ModelContext) {
        do {
            let defaultAccount: ExpenseAccount = ExpenseAccount.getDefault(with: context)
            
            let expenseFetch = FetchDescriptor<Expense>(
                predicate: #Predicate { $0.account == nil }
            )
            let expensesWithoutAccount = try context.fetch(expenseFetch)
            
            for expense in expensesWithoutAccount {
                expense.account = defaultAccount
            }
            
            try context.save()
        } catch {
            
        }
    }
    
    /// Safely deletes an account by reassigning its expenses to the default accounts.
    /// This method ensures no expenses are orphaned when an account is deleted.
    func deleteSafely(from context: ModelContext) {
        guard !isDefault else { return }
        do {
            let descriptor = FetchDescriptor<ExpenseAccount>(predicate: #Predicate { $0.isDefault })
            guard let defaultAccount = try context.fetch(descriptor).first else {
                print("Could not find default account. Aborting delete.")
                return
            }
            if let expensesToReassign = expenses {
                for expense in expensesToReassign {
                    expense.account = defaultAccount
                }
            }
            context.delete(self)
            try context.save()
        } catch {
            print("Failed to delete account: \(error)")
        }
    }
    
    static func consolidateDefaultAccounts(in context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseAccount>(predicate: #Predicate { $0.isDefault })
        do {
            let defaultAccounts = try context.fetch(descriptor)
            guard defaultAccounts.count > 1 else { return }

            let sortedDefaults = defaultAccounts.sorted {
                ($0.expenses?.count ?? 0) > ($1.expenses?.count ?? 0)
            }
            let survivor = sortedDefaults[0]
            for duplicate in sortedDefaults.dropFirst() {
                if let expensesToMove = duplicate.expenses {
                    for expense in Array(expensesToMove) {
                        expense.account = survivor
                    }
                }
                context.delete(duplicate)
            }
            resetDefaultAccounts(in: context)
            survivor.isDefault = true
            try context.save()
        } catch {
            print("Failed to consolidate default accounts: \(error)")
        }
    }

    static func resetDefaultAccounts(in context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseAccount>()
        if let allAccounts = try? context.fetch(descriptor) {
            for acc in allAccounts {
                acc.isDefault = false
            }
        }
    }
}

// MARK: - Account Draft struct for creating and editing Accounts

struct AccountDraft: Equatable {
    var name: String
    var iconName: String
    var isDefault: Bool
    var sortOrder: Int
    
    init(name: String, iconName: String, isDefault: Bool = false, sortOrder: Int = 0) {
        self.name = name
        self.iconName = iconName
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
    
    init(from account: ExpenseAccount) {
        self.name = account.name
        self.iconName = account.iconName
        self.isDefault = account.isDefault
        self.sortOrder = account.sortOrder
    }
    
    static func createNew(sortOrder: Int = 0) -> AccountDraft {
        AccountDraft(
                name: "",
                iconName: "tag",
                isDefault: false,
                sortOrder: sortOrder
        )
    }
}
