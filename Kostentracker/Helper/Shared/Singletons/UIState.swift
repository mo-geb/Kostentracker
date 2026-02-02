import Foundation
import SwiftData
import SwiftUI

final class UIState: ObservableObject {
    static let shared = UIState()

    // MARK: - Published UI States
    
    // Modals / Sheets
    @Published var activeExpenseSheet: ActiveExpenseSheet?
    @Published var activeCategorySheet: ActiveCategorySheet?
    @Published var activeAccountSheet: ActiveAccountSheet?
    @Published var showingSettings: Bool = false

    // Toasts
    @Published var activePopup: ActivePopup?
    @Published var feedbackTrigger: Bool = false

    // UI Configuration
    @AppStorage("selectedFilter") var selectedFilter: FilterOption = .all
    @AppStorage("selectedSort") var selectedSort: SortOption = .amountDescending
    @AppStorage("selectedGroupBy") var selectedGroupBy: GroupByOption = .categories
    @AppStorage("selectedViewMode") var selectedViewMode: ViewMode = .normal
    @AppStorage("selectedDisplayPeriod") var selectedDisplayPeriod: FrequencyUnit = .month
    @AppStorage("displayedCategoryChart") var displayedCategoryChart: CategoryChart = .barChart
    @Published var selectedAccountIDs: Set<UUID> = [] { didSet { saveAccounts() }}

    init() {
        loadAccounts()
    }
    
    // MARK: - Sheet Workflows

    func showSettings() {
        showingSettings = true
    }

    func editExpense(_ expense: Expense) {
        activeExpenseSheet = .edit(expense)
    }

    func viewExpense(_ expense: Expense) {
        activeExpenseSheet = .view(expense)
    }

    func createExpense(from draft: ExpenseDraft) {
        activeExpenseSheet = .new(draft)
    }

    func editCategory(_ category: ExpenseCategory) {
        activeCategorySheet = .edit(category)
    }

    func createCategory(from draft: CategoryDraft) {
        activeCategorySheet = .new(draft)
    }
    
    func editAccount(_ account: ExpenseAccount) {
        activeAccountSheet = .edit(account)
    }

    func createAccount(from draft: AccountDraft) {
        activeAccountSheet = .new(draft)
    }
    
    // MARK: - Account management
    
    private let accountsKey = "selectedAccountIDs"
    
    private func saveAccounts() {
        do {
            let data = try JSONEncoder().encode(selectedAccountIDs)
            UserDefaults.standard.set(data, forKey: accountsKey)
        } catch {
            print("Failed to encode account IDs: \(error)")
        }
    }

    private func loadAccounts() {
        guard let data = UserDefaults.standard.data(forKey: accountsKey),
              let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            return
        }
        self.selectedAccountIDs = decoded
    }
    
    func getAccountSelected(account: ExpenseAccount) -> Bool {
        return selectedAccountIDs.contains(account.uuid)
    }
    
    func toggleAccountSelected(for account: ExpenseAccount, forceTo: Bool? = nil) {
        let targetState = forceTo ?? !selectedAccountIDs.contains(account.uuid)
        
        if targetState {
            selectedAccountIDs.insert(account.uuid)
        } else {
            selectedAccountIDs.remove(account.uuid)
        }
    }
    
    func getAllAccountsSelected(accounts: [ExpenseAccount]) -> Bool {
        guard !accounts.isEmpty else { return false }
        return accounts.allSatisfy { selectedAccountIDs.contains($0.uuid) }
    }
    
    func toggleAllAccounts(accounts: [ExpenseAccount], forceTo: Bool? = nil) {
        let targetState = forceTo ?? !getAllAccountsSelected(accounts: accounts)
        
        if targetState {
            selectedAccountIDs.formUnion(accounts.map { $0.uuid })
        } else {
            selectedAccountIDs.removeAll()
        }
    }

    // MARK: - Popup / Transient Feedback

    func showMarkedAsPaidConfirmation(owner: ActivePopup.PopupOwner, duration: TimeInterval = 1.5) {
        withAnimation {
            self.feedbackTrigger.toggle()
            self.activePopup = .markedAsPaid(owner: owner)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                self.activePopup = nil
            }
        }
    }
    
    func showDeletedPopup(owner: ActivePopup.PopupOwner, duration: TimeInterval = 1.5) {
        withAnimation {
            self.feedbackTrigger.toggle()
            self.activePopup = .deleted(owner: owner)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                self.activePopup = nil
            }
        }
    }
}

