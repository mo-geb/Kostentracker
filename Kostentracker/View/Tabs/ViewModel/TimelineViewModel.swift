import SwiftUI
import SwiftData

@Observable
final class TimelineViewModel {
    
    struct MonthlyExpenseGroup: Identifiable {
        let id: Date
        var month: Date
        var expenses: [Expense]
        var totalAmount: Double
    }
    
    var monthlyGroups: [MonthlyExpenseGroup] = []
    
    func update(from unfilteredExpenses: [Expense], ui: UIState, userSettings: UserSettings) {
        let filteredExpenses = filtered(unfilteredExpenses, ui: ui, userSettings: userSettings)
        let onlyActive = Expense.applyCustomFilters(filteredExpenses, filter: .active)
        let calendar = Calendar.current
        
        // Group expenses by the start of their month
        let groupedByMonth = Dictionary(grouping: onlyActive) { expense in
            calendar.date(from: calendar.dateComponents([.year, .month], from: expense.date))!
        }
        
        // Transform the grouped dictionary into an array of MonthlyExpenseGroup
        self.monthlyGroups = groupedByMonth.map { (month, expensesInMonth) in
            let total = expensesInMonth.reduce(0.0) { sum, expense in
                sum + expense.totalForMonth(containing: month)
            }
            
            let sortedExpenses = expensesInMonth.sorted { $0.date < $1.date }
            return MonthlyExpenseGroup(id: month, month: month, expenses: sortedExpenses, totalAmount: total)
        }
        .sorted { $0.month < $1.month } // Sort by month ascending
    }
    
    /// Returns the filtered expenses
    func filtered(_ expenses: [Expense], ui: UIState, userSettings: UserSettings) -> [Expense] {
        let accountFiltered = userSettings.enableAccounts ? Expense.applyAccountsFilters(expenses, selectedIDs: ui.selectedAccountIDs) : expenses
        return Expense.applyCustomFilters(accountFiltered, filter: ui.selectedFilter)
    }
    
    // Global action execution
    func markAsPaidOrDelete(_ expense: Expense, context: ModelContext, ui: UIState) {
        switch expense.type {
        case .oneTime, .inactive:
            context.delete(expense)
            ui.showDeletedPopup(owner: .main)
        case .recurring:
            expense.advanceDueDate()
            ui.showMarkedAsPaidConfirmation(owner: .main)
        }
        
        try? context.save()
    }
}
