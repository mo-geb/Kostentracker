import Foundation
import SwiftData
import SwiftUI

@Observable
final class UIState {
    // MARK: - Published UI States
    
    // Modals / Sheets
    var activeExpenseSheet: ActiveExpenseSheet?
    var activeCategorySheet: ActiveCategorySheet?
    var activeAccountSheet: ActiveAccountSheet?
    var showingSettings: Bool = false
    var showingPaywall: Bool = false

    // Toasts
    var activePopup: ActivePopup?
    var feedbackTrigger: Bool = false

    // UI Configuration
    var selectedFilter: FilterOption { didSet { persist(key: "selectedFilter", value: selectedFilter.rawValue) }}
    var selectedSort: SortOption { didSet { persist(key: "selectedSort", value: selectedSort.rawValue) }}
    var selectedGroupBy: GroupByOption { didSet { persist(key: "selectedGroupBy", value: selectedGroupBy.rawValue) }}
    var selectedViewMode: ViewMode { didSet { persist(key: "selectedViewMode", value: selectedViewMode.rawValue) }}
    var selectedDisplayPeriod: FrequencyUnit { didSet { persist(key: "selectedDisplayPeriod", value: selectedDisplayPeriod.rawValue) }}
    var displayedCategoryChart: CategoryChart { didSet { persist(key: "displayedCategoryChart", value: displayedCategoryChart.rawValue) }}
    var selectedAccountIDs: Set<UUID> = [] { didSet { saveAccounts() }}

    init() {
        let defaults = UserDefaults.standard
                
        self.selectedFilter = defaults.getEnum(forKey: "selectedFilter", default: .all)
        self.selectedSort = defaults.getEnum(forKey: "selectedSort", default: .amountDescending)
        self.selectedGroupBy = defaults.getEnum(forKey: "selectedGroupBy", default: .categories)
        self.selectedViewMode = defaults.getEnum(forKey: "selectedViewMode", default: .normal)
        self.selectedDisplayPeriod = defaults.getEnum(forKey: "selectedDisplayPeriod", default: .month)
        self.displayedCategoryChart = defaults.getEnum(forKey: "displayedCategoryChart", default: .barChart)
        
        loadAccounts()
    }
    
    // MARK: - Sheet Workflows

    func showSettings() {
        showingSettings = true
    }

    func presentPaywall() {
        showingPaywall = true
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
    
    func persist(key: String, value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

