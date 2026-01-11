import Foundation
import SwiftData
import SwiftUI

@Model
final class Expense: Identifiable {
    var title: String = ""
    var amount: Double = 0
    var frequencyUnit: FrequencyUnit = FrequencyUnit.month
    var frequencyValue: Int16 = 1
    var date: Date = Date()
    var category: ExpenseCategory?
    var notes: String = ""
    @Attribute(.externalStorage) var customImageData: Data?
    
    /// Create from a draft
    init(from draft: ExpenseDraft) {
        self.title = draft.title
        self.amount = draft.amount
        self.frequencyUnit = draft.frequencyUnit
        self.frequencyValue = draft.frequencyValue
        self.date = draft.date
        self.category = draft.category
        self.notes = draft.notes
        self.customImageData = draft.customImageData
    }
    
    /// Update based on a draft
    func update(from draft: ExpenseDraft) {
        self.title = draft.title
        self.amount = draft.amount
        self.frequencyUnit = draft.frequencyUnit
        self.frequencyValue = draft.frequencyValue
        self.date = draft.date
        self.category = draft.category
        self.notes = draft.notes
        self.customImageData = draft.customImageData
    }
}

// MARK: - Accessibility

extension Expense {
    /// VoiceOver-friendly description including expense details
    var accessibilityLabel: String {
        let userSettings = UserSettings.shared
        let formattedAmount = String(format: "%.2f", amount)
        let frequency = frequencyUnit.displayText(for: frequencyValue)
        
        return "\(title), \(formattedAmount) \(userSettings.currencyCode), \(categoryName), \(frequency)"
    }
}

// MARK: - Access helpers

extension Expense {
    var yearlyCost: Double {
        let frequencyValue = Double(self.frequencyValue)
        guard frequencyValue > 0 else { return 0 }
        switch self.frequencyUnit {
        case .day: return self.amount * (365.0 / frequencyValue)
        case .week: return self.amount * (52.0 / frequencyValue)
        case .month: return self.amount * (12.0 / frequencyValue)
        case .year: return self.amount / frequencyValue
        }
    }
    
    var monthlyCost: Double {
        return yearlyCost / 12.0
    }

    var weeklyCost: Double {
        return yearlyCost / 52.0
    }

    var dailyCost: Double {
        return yearlyCost / 365.0
    }
    
    var categoryColor: Color { category?.color ?? .gray }
    var categoryIconName: String { category?.iconName ?? "tag" }
    var categoryName: String { category?.name ?? "Other" }
    var categorySortOrder: Int { category?.sortOrder ?? 1 }
    var type: ExpenseType { date == .distantPast ? .inactive : frequencyValue == 0 ? .oneTime : .recurring}
}

// MARK: - Functions

extension Expense {
    func getCostFor(for selectedPeriod: FrequencyUnit) -> Double {
        switch selectedPeriod {
        case .year:
            return yearlyCost
        case .month:
            return monthlyCost
        case .week:
            return weeklyCost
        case .day:
            return dailyCost
        }
    }
    
    func advanceDueDate() {
        withAnimation {
            let calendar = Calendar.current
            var dateComponent: Calendar.Component
            
            switch self.frequencyUnit {
            case .day: dateComponent = .day
            case .week: dateComponent = .weekOfYear
            case .month: dateComponent = .month
            case .year: dateComponent = .year
            }
            
            if let newDate = calendar.date(byAdding: dateComponent, value: Int(self.frequencyValue), to: self.date) {
                self.date = newDate
            }
        }
    }
    
    /// Calculates the total cost of this expense for a specific month
    func totalForMonth(containing date: Date) -> Double {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        let normalizedSelfDate = calendar.startOfDay(for: self.date)
        var currentDate = normalizedSelfDate
        var monthTotal = 0.0
        
        if type == .oneTime {
            return currentDate < monthEnd && currentDate >= monthStart ? self.amount : 0
        }

        while currentDate < monthEnd {
            if currentDate >= monthStart {
                monthTotal += self.amount
            }

            let dateComponent: Calendar.Component
            switch frequencyUnit {
            case .day: dateComponent = .day
            case .week: dateComponent = .weekOfYear
            case .month: dateComponent = .month
            case .year: dateComponent = .year
            }

            guard let nextDate = calendar.date(byAdding: dateComponent, value: Int(frequencyValue), to: currentDate) else { break }
            currentDate = nextDate
        }

        return monthTotal
    }

    
    /// Returns true if this expense occurs multiple times in the given month
    func hasMultipleOccurrencesInMonth(containing date: Date) -> Bool {
        switch type {
        case .inactive, .oneTime: return false
        case .recurring:
            let total = totalForMonth(containing: date)
            return total > amount
        }
    }
}

// MARK: - Static mathods to apply on collections

extension Expense {
    static func applyCustomFilters(_ expenses: [Expense], filter: FilterOption) -> [Expense] {
        var filtered = expenses
        switch filter {
        case .all:
            break
        case .nonZero:
            filtered = filtered.filter { $0.yearlyCost > 0 }
        case .upcoming:
            let nextThirtyDays = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date <= nextThirtyDays }
        }
        return filtered
    }
    
    /// Sorts an array of expenses based on the `selectedSort` state.
    static func sortExpenses(expenses: [Expense], sortOption: SortOption) -> [Expense] {
        switch sortOption {
        case .amountDescending:
            return expenses.sorted { $0.yearlyCost > $1.yearlyCost }
        case .amountAscending:
            return expenses.sorted { $0.yearlyCost < $1.yearlyCost }
        case .title:
            return expenses.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
}

// MARK: - Expense Draft struct for creating and editing Expenses

struct ExpenseDraft {
    var title: String
    var amount: Double
    var frequencyUnit: FrequencyUnit
    var frequencyValue: Int16
    var date: Date
    var category: ExpenseCategory?
    var notes: String
    var customImageData: Data?
    
    init(title: String, amount: Double, frequencyUnit: FrequencyUnit, frequencyValue: Int16, date: Date, category: ExpenseCategory?, notes: String, customImageData: Data? = nil) {
        self.title = title
        self.amount = amount
        self.frequencyUnit = frequencyUnit
        self.frequencyValue = frequencyValue
        self.date = date
        self.category = category
        self.notes = notes
        self.customImageData = customImageData
    }
    
    /// Create from an Expense
    init(from expense: Expense) {
        self.title = expense.title
        self.amount = expense.amount
        self.frequencyUnit = expense.frequencyUnit
        self.frequencyValue = expense.frequencyValue
        self.date = expense.date
        self.category = expense.category
        self.notes = expense.notes
        self.customImageData = expense.customImageData
    }
    
    /// Create new (with context for default category)
    static func createNew(with context: ModelContext) -> ExpenseDraft {
        ExpenseDraft(
            title: "",
            amount: 0,
            frequencyUnit: .month,
            frequencyValue: 1,
            date: Date(),
            category: ExpenseCategory.getDefault(with: context),
            notes: "",
            customImageData: nil
        )
    }
}

extension ExpenseDraft {
    var type: ExpenseType { frequencyValue == 0 ? .oneTime : .recurring}
}
