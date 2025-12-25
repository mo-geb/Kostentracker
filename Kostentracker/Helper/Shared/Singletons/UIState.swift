import Foundation
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
    @AppStorage("selectedFilter") var selectedFilter: FilterOption = .nonZero
    @AppStorage("selectedSort") var selectedSort: SortOption = .amountDescending
    @AppStorage("selectedGroupBy") var selectedGroupBy: GroupByOption = .categories
    @AppStorage("selectedViewMode") var selectedViewMode: ViewMode = .normal
    @AppStorage("selectedDisplayPeriod") var selectedDisplayPeriod: FrequencyUnit = .month
    @AppStorage("displayedCategoryChart") var displayedCategoryChart: CategoryChart = .barChart

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

    // MARK: - Popup / Transient Feedback

    func showMarkedAsPaidConfirmation(owner: ActivePopup.MarkedAsPaidOwner, duration: TimeInterval = 1.5) {
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
}

