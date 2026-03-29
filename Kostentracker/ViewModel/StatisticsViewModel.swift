import SwiftUI
import SwiftData

@Observable
final class StatisticsViewModel {
    
    // MARK: - Cached Properties
    
    typealias TotalCosts = (yearly: Double, monthly: Double, weekly: Double)
    
    struct CategoryCost: Identifiable {
        let id: ExpenseCategory
        var category: Expense
        var totalCost: Double
    }
    
    struct MonthlyCategoryExpense: Identifiable {
        let id = UUID()
        let date: Date
        let category: ExpenseCategory
        let amount: Double
    }
    
    var totalCosts: TotalCosts = (0, 0, 0)
    var categoryCosts: [CategoryCost] = []
    var displayMonths: [Date] = []
    var monthlyCategoryExpenses: [MonthlyCategoryExpense] = []
    var averageMonthlyDisplayed: Double = 0
    var hasExpenses: Bool = false

    // MARK: - Update Action
    
    func update(from unfilteredExpenses: [Expense], ui: UIState, userSettings: UserSettings, context: ModelContext) {
        let expenses = filtered(unfilteredExpenses, ui: ui, userSettings: userSettings)
        self.hasExpenses = !expenses.isEmpty
        
        guard self.hasExpenses else {
            self.totalCosts = (0, 0, 0)
            self.categoryCosts = []
            self.displayMonths = []
            self.monthlyCategoryExpenses = []
            self.averageMonthlyDisplayed = 0
            return
        }
        
        self.totalCosts = computeTotalCosts(from: expenses)
        self.categoryCosts = computeCategoryCosts(from: expenses, context: context)
        self.displayMonths = computeMonthsToDisplay(from: expenses)
        self.monthlyCategoryExpenses = computeMonthlyCostsWithCategories(from: expenses, displayMonths: self.displayMonths)
        self.averageMonthlyDisplayed = computeAverageMonthlyDisplayed(from: expenses, displayMonths: self.displayMonths)
    }

    // MARK: - Private Computation Helpers
    
    private func computeTotalCosts(from expenses: [Expense]) -> TotalCosts {
        let yearlyTotal = expenses.reduce(0) { $0 + $1.yearlyCost }
        return (yearlyTotal, yearlyTotal / 12, yearlyTotal / 52)
    }
    
    private func computeCategoryCosts(from expenses: [Expense], context: ModelContext) -> [CategoryCost] {
        let groupedByCategory = Dictionary(grouping: expenses, by: { $0.category })
        return groupedByCategory.compactMap { (category, expenses) in
            guard let firstExpense = expenses.first else { return nil }
            let totalCostForCategory = expenses.reduce(0) { $0 + $1.yearlyCost }
            guard totalCostForCategory > 0 else { return nil }
            return CategoryCost(id: category ?? ExpenseCategory.getDefault(with: context), category: firstExpense, totalCost: totalCostForCategory)
        }
        .sorted { $0.totalCost > $1.totalCost }
    }
    
    private func computeMonthlyCostsWithCategories(from expenses: [Expense], displayMonths: [Date]) -> [MonthlyCategoryExpense] {
        var resultDict: [Date: [ExpenseCategory: Double]] = [:]
        
        for date in displayMonths {
            resultDict[date] = [:]
        }

        for expense in expenses where expense.type != .inactive {
            guard let category = expense.category else { continue }
            
            for monthDate in displayMonths {
                let amount = expense.totalForMonth(containing: monthDate)
                if amount > 0 {
                    resultDict[monthDate, default: [:]][category, default: 0] += amount
                }
            }
        }

        return resultDict.flatMap { (date, categories) in
            categories.map { MonthlyCategoryExpense(date: date, category: $0.key, amount: $0.value) }
        }.sorted {
            if $0.date != $1.date {
                return $0.date < $1.date
            } else if $0.category.sortOrder != $1.category.sortOrder {
                return $0.category.sortOrder < $1.category.sortOrder
            } else {
                return $0.category.name < $1.category.name
            }
        }
    }
    
    private func computeMonthsToDisplay(from expenses: [Expense]) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        
        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = 1
        components.hour = 12 // Use Noon to avoid timezone shifting to the previous day
        
        let currentMonthStart = calendar.date(from: components)!
        let upperBound = calendar.date(byAdding: .month, value: 11, to: currentMonthStart)!
        
        let earliestDate = expenses
            .filter { $0.type != .inactive }
            .map { $0.normalizedDate }
            .min() ?? now
        
        var earliestComponents = calendar.dateComponents([.year, .month], from: earliestDate)
        earliestComponents.day = 1
        earliestComponents.hour = 12
        let earliestExpenseMonth = calendar.date(from: earliestComponents)!
        
        let lowerBound = min(earliestExpenseMonth, currentMonthStart)
        
        var months: [Date] = []
        var cursor = lowerBound
        
        while cursor <= upperBound {
            months.append(cursor)
            cursor = calendar.date(byAdding: .month, value: 1, to: cursor)!
        }
        
        return months
    }
    
    private func computeAverageMonthlyDisplayed(from expenses: [Expense], displayMonths: [Date]) -> Double {
        guard !displayMonths.isEmpty else { return 0 }
        let activeExpenses = expenses.filter { $0.type != .inactive }
        
        let monthlyTotals = displayMonths.map { monthDate in
            activeExpenses.reduce(0.0) { $0 + $1.totalForMonth(containing: monthDate) }
        }
        return monthlyTotals.reduce(0, +) / Double(monthlyTotals.count)
    }
    
    /// Returns the filtered expenses
    func filtered(_ expenses: [Expense], ui: UIState, userSettings: UserSettings) -> [Expense] {
        let accountFiltered = userSettings.enableAccounts ? Expense.applyAccountsFilters(expenses, selectedIDs: ui.selectedAccountIDs) : expenses
        return Expense.applyCustomFilters(accountFiltered, filter: .active)
    }
}
