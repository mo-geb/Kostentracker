import Foundation
import SwiftData
import SwiftUI

@Model
class Expense: Identifiable {
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
    
    var categoryColor: Color { category?.color ?? .gray }
    var categoryIconName: String { category?.iconName ?? "tag" }
    var categoryName: String { category?.name ?? "Other" }
    var categorySortOrder: Int { category?.sortOrder ?? 1 }
}

// MARK: - Functions

extension Expense {
    func markAsPaid() {
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
        let total = totalForMonth(containing: date)
        return total > amount
    }
    
    /// Compact row: just icon and title/cost
    func createCompactRow(convertedAmount: Double, currencyCode: String) -> some View {
        let isZero: Bool = convertedAmount == 0

        return HStack(spacing: 8) {
            if let imageData = customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.3))
                        .frame(width: 20, height: 20)
                    Image(systemName: categoryIconName)
                        .font(.caption)
                        .foregroundStyle(categoryColor)
                }
            }
            Text(title)
                .font(.body)
                .foregroundStyle(isZero ? .secondary : .primary)
            Spacer()
            Text(convertedAmount, format: .currency(code: currencyCode))
                .fontWeight(.medium)
                .font(.body)
                .foregroundStyle(isZero ? .secondary : .primary)
        }
    }
    
    /// Normal row: icon, title, subtitle, cost
    func createNormalRow(subtitle: String, convertedAmount: Double, currencyCode: String, displayTotal: Bool = false) -> some View {
        let isOverdue: Bool = {
            // Try to parse the subtitle as a date in the same format used in TimelineView
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            if let date = formatter.date(from: subtitle) {
                return date < Calendar.current.startOfDay(for: Date())
            }
            return false
        }()
        
        let isZero: Bool = convertedAmount == 0
        
        return HStack(spacing: 12) {
            if let imageData = customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.3))
                        .frame(width: 40, height: 40)
                    Image(systemName: categoryIconName)
                        .font(.title2)
                        .foregroundStyle(categoryColor)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(isZero ? .secondary : .primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(isOverdue ? Color.red : Color.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(convertedAmount, format: .currency(code: currencyCode))
                    .fontWeight(.medium)
                    .foregroundStyle(isZero ? .secondary : .primary)
                if displayTotal && hasMultipleOccurrencesInMonth(containing: date) {
                    let monthTotal = totalForMonth(containing: date)
                    Text(monthTotal, format: .currency(code: currencyCode))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Static mathods to apply on collections

extension Expense {
    static func applyFilters(_ expenses: [Expense], filter: FilterOption) -> [Expense] {
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
