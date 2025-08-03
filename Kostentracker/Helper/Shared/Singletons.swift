import Foundation
import SwiftUI

// MARK: - User Settings

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("currencyCode") var currencyCode: String = "EUR"
    @AppStorage("enableAccounts") var enableAccounts: Bool = false
}

// MARK: - UI State

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

    // UI Configuration
    @Published var selectedFilter: FilterOption = .nonZero
    @Published var selectedSort: SortOption = .amountDescending
    @Published var selectedGroupBy: GroupByOption = .categories
    @Published var selectedViewMode: ViewMode = .normal

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

    func dismissAllSheets() {
        activeExpenseSheet = nil
        activeCategorySheet = nil
        showingSettings = false
    }

    // MARK: - Popup / Transient Feedback

    func showMarkedAsPaidConfirmation(owner: ActivePopup.MarkedAsPaidOwner, duration: TimeInterval = 1.5) {
        performHapticFeedback()
        withAnimation {
            self.activePopup = .markedAsPaid(owner: owner)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                self.activePopup = nil
            }
        }
    }

    func performHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
    }
}

