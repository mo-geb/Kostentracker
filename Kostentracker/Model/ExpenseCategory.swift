import SwiftUI
import SwiftData
import UIKit

@Model
final class ExpenseCategory: Identifiable {
    var name: String = ""
    var iconName: String = ""
    var hexColor: String = ""
    var isDefault: Bool = false
    var sortOrder: Int = 0
    // Nullify (not cascade): if a category is deleted directly, expenses survive
    // and fall back to the "Other" label via Expense.categoryName. Safe deletion
    // via deleteSafely() reassigns to the default category before delete.
    @Relationship(deleteRule: .nullify, inverse: \Expense.category) var expenses: [Expense]?
    
    /// A computed property to easily get the SwiftUI Color.
    var color: Color {
        Color(hex: hexColor)
    }
    
    /// Create Category based on draft
    init(from draft: CategoryDraft) {
        self.name = draft.name
        self.iconName = draft.iconName
        self.hexColor = draft.hexColor
        self.isDefault = draft.isDefault
        self.sortOrder = draft.sortOrder
    }
    
    /// Update based on draft
    func update(from draft: CategoryDraft) {
        self.name = draft.name
        self.iconName = draft.iconName
        self.hexColor = draft.hexColor
        self.isDefault = draft.isDefault
        self.sortOrder = draft.sortOrder
    }
}

extension ExpenseCategory {
    static func getDefault(with context: ModelContext) -> ExpenseCategory {
        let descriptor = FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.isDefault })
        if let defaultCategory = try? context.fetch(descriptor).first {
            return defaultCategory
        }
        let defaultCategory = createDefault()
        context.insert(defaultCategory)
        return defaultCategory
    }
    
    static func createDefault() -> ExpenseCategory {
        return ExpenseCategory(from: CategoryDraft(name: String(localized: "Other"), iconName: "tag", color: .gray, isDefault: true))
    }
    
    /// Safely deletes a category by reassigning its expenses to the default category.
    /// This method ensures no expenses are orphaned when a category is deleted.
    func deleteSafely(from context: ModelContext) {
        guard !isDefault else { return }
        do {
            let descriptor = FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.isDefault })
            guard let defaultCategory = try context.fetch(descriptor).first else {
                print("Could not find default category. Aborting delete.")
                return
            }
            if let expensesToReassign = expenses {
                for expense in expensesToReassign {
                    expense.category = defaultCategory
                }
            }
            context.delete(self)
            try context.save()
        } catch {
            print("Failed to delete category: \(error)")
        }
    }
    
    static func resetDefaultCategories(in context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseCategory>()
        if let allCategories = try? context.fetch(descriptor) {
            for cat in allCategories {
                cat.isDefault = false
            }
        }
    }
    
    static func deleteEmptyDefaultCategories(in context: ModelContext) {
        let defaultCategory = createDefault()
        let targetName = defaultCategory.name
        let targetIcon = defaultCategory.iconName
        let targetColor = defaultCategory.hexColor

        let defaultPredicate = FetchDescriptor<ExpenseCategory>(
            predicate: #Predicate<ExpenseCategory> { category in
                category.name == targetName &&
                category.iconName == targetIcon &&
                category.hexColor == targetColor
            }
        )
        
        do {
            let defaultCategories = try context.fetch(defaultPredicate)
            let emptyDefaultCategories = defaultCategories.filter { ($0.expenses?.count ?? 0) == 0 }
            guard emptyDefaultCategories.count > 0 else { return }
            
            for empty in emptyDefaultCategories {
                empty.deleteSafely(from: context)
            }
            try context.save()
            print("Consolidation complete. One default category remains.")
            
        } catch {
            print("Failed to consolidate default categories: \(error)")
        }
    }
    
    static func consolidateDefaultCategories(in context: ModelContext) {
            let descriptor = FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.isDefault })
            
            do {
                let defaultCategories = try context.fetch(descriptor)

                guard defaultCategories.count > 1 else { return }
                
                print("Found \(defaultCategories.count) default categories. Starting consolidation...")
                
                let sortedDefaults = defaultCategories.sorted {
                    ($0.expenses?.count ?? 0) > ($1.expenses?.count ?? 0)
                }
                
                let survivor = sortedDefaults[0]
                let duplicates = sortedDefaults.dropFirst()
                
                for duplicate in duplicates {
                    print("Merging duplicate default category: \(duplicate.name) with \(duplicate.expenses?.count ?? 0) expenses")
                    
                    if let expensesToMove = duplicate.expenses {
                        // Create a copy of the array to avoid mutation issues during iteration
                        let expensesArray = Array(expensesToMove)
                        for expense in expensesArray {
                            expense.category = survivor
                        }
                    }
                    context.delete(duplicate)
                }
                resetDefaultCategories(in: context)
                survivor.isDefault = true
                
                try context.save()
                print("Consolidation complete. One default category remains.")
                
            } catch {
                print("Failed to consolidate default categories: \(error)")
            }
        }
}

// MARK: - Category Draft struct for creating and editing Categories

struct CategoryDraft {
    var name: String
    var iconName: String
    var hexColor: String
    var isDefault: Bool
    var sortOrder: Int
    
    init(name: String, iconName: String, color: Color, isDefault: Bool = false, sortOrder: Int = 0) {
        self.name = name
        self.iconName = iconName
        self.hexColor = color.toHex() ?? "000000"
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
    
    init(from category: ExpenseCategory) {
        self.name = category.name
        self.iconName = category.iconName
        self.hexColor = category.hexColor
        self.isDefault = category.isDefault
        self.sortOrder = category.sortOrder
    }
    
    static func createNew(sortOrder: Int = 0) -> CategoryDraft {
        CategoryDraft(
                name: "",
                iconName: "tag",
                color: .blue,
                isDefault: false,
                sortOrder: sortOrder
        )
    }
}
