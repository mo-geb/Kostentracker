import SwiftUI
import SwiftData

@Observable
final class ListViewModel {
    
    // MARK: - Data Processing
    
    /// A struct to hold the processed data for each group.
    struct ProcessedGroup: Identifiable, Equatable {
        let id: String
        var title: String
        var totalCost: Double
        var expenses: [Expense]
    }
    
    var processedGroups: [ProcessedGroup] = []
    
    /// Groups, sorts, and calculates costs based on user selections.
    func update(from unfilteredExpenses: [Expense], ui: UIState, userSettings: UserSettings) {
        let filteredExpenses = filtered(unfilteredExpenses, ui: ui, userSettings: userSettings)
        let grouped: [String: [Expense]]
        
        switch ui.selectedGroupBy {
        case .none:
            grouped = ["all": filteredExpenses]
        case .categories:
            grouped = Dictionary(grouping: filteredExpenses, by: { $0.categoryName })
        case .frequency:
            grouped = Dictionary(grouping: filteredExpenses) { expense in
                switch expense.type {
                case .oneTime:
                    return String(localized: "One time")
                case .inactive:
                    return String(localized: "Inactive")
                case .recurring:
                    return expense.frequencyUnit.rawValue.capitalized
                }
            }
        }
        
        let processed = grouped.map { (key, expenses) -> ProcessedGroup in
            let total = expenses.reduce(0) { $0 + $1.getCostFor(for: ui.selectedDisplayPeriod) }
            let sortedExpenses = Expense.sortExpenses(expenses: expenses, sortOption: ui.selectedSort)
            let title = ui.selectedGroupBy == .none ? String(localized: "All Expenses") : key
            return ProcessedGroup(id: key, title: title, totalCost: total, expenses: sortedExpenses)
        }
        
        self.processedGroups = sortGroups(groups: processed, groupBy: ui.selectedGroupBy)
    }
    
    /// Returns the filtered expenses
    func filtered(_ expenses: [Expense], ui: UIState, userSettings: UserSettings) -> [Expense] {
        let accountFiltered = userSettings.enableAccounts ? Expense.applyAccountsFilters(expenses, selectedIDs: ui.selectedAccountIDs) : expenses
        return Expense.applyCustomFilters(accountFiltered, filter: ui.selectedFilter)
    }
    
    /// Sorts an array of groups based on the `selectedGroupBy` state.
    private func sortGroups(groups: [ProcessedGroup], groupBy: GroupByOption) -> [ProcessedGroup] {
        switch groupBy {
        case .none:
            return groups
        case .categories:
            return groups.sorted {
                guard
                    let firstA = $0.expenses.first,
                    let firstB = $1.expenses.first
                else { return false }
                return firstA.categorySortOrder < firstB.categorySortOrder
            }
        case .frequency:
            return groups.sorted { a, b in
                func rank(_ title: String) -> (Int, Int) {
                    let key = title.lowercased()
                    
                    // Special groups
                    if key == "inactive" {
                        return (2, 0)
                    }
                    if key == "one-time" {
                        return (1, 0)
                    }
                    
                    // Normal frequency units
                    if let unit = FrequencyUnit(rawValue: key) {
                        return (0, unit.sortOrder)
                    }
                    
                    // Fallback
                    return (0, Int.max)
                }
                
                let ra = rank(a.title)
                let rb = rank(b.title)
                
                return ra < rb
            }
        }
    }
}
