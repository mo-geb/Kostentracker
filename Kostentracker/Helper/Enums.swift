//
//  Enums.swift
//  Kostentracker
//

import Foundation
import SwiftData

// MARK: - Enum Definitions

enum FrequencyUnit: String, Codable, CaseIterable {
    case day, week, month, year
}

enum SortOption: LocalizedStringResource, CaseIterable, Identifiable {
    case amountDescending = "Amount (High to Low)"
    case amountAscending = "Amount (Low to High)"
    case title = "Title (A-Z)"
    
    var id: Self { self }
}

enum CostPeriod: LocalizedStringResource, CaseIterable, Identifiable {
    case yearly = "Yearly"
    case monthly = "Monthly"
    case weekly = "Weekly"
    case daily = "Daily"
    
    var id: Self { self }
}

enum FilterOption: LocalizedStringResource, CaseIterable, Identifiable {
    case all = "All Expenses"
    case nonZero = "Non-Zero Cost"
    case upcoming = "Upcoming (Next 30 Days)"
    
    var id: Self { self }
}

enum GroupByOption: LocalizedStringResource, CaseIterable, Identifiable {
    case none = "None"
    case categories = "Categories"
    case frequencyUnit = "Frequency"
    
    var id: Self { self }
}

enum ViewMode: LocalizedStringResource, CaseIterable, Identifiable {
    case normal = "Normal"
    case compact = "Compact"
    
    var id: Self { self }
}

enum FocusedField: Hashable {
    case expenseDetailTitle, expenseDetailAmount, expenseDetailNotes, categoryDetailTitle
}

enum ActiveExpenseSheet: Identifiable, Equatable {
    case view(Expense)
    case new(ExpenseDraft)
    case edit(Expense)
    
    var id: String {
        switch self {
        case .view(let expense): return expense.persistentModelID.entityName
        case .new(_): return "new"
        case .edit(let expense): return expense.persistentModelID.entityName
        }
    }
    
    static func == (lhs: ActiveExpenseSheet, rhs: ActiveExpenseSheet) -> Bool {
        switch (lhs, rhs) {
        case (.view(let l), .view(let r)): return l.id == r.id
        case (.new(let l), .new(let r)): return l.category?.persistentModelID == r.category?.persistentModelID
        case (.edit(let l), .edit(let r)): return l.id == r.id
        default: return false
        }
    }
}

enum ActiveCategorySheet: Identifiable, Equatable {
    case new(CategoryDraft)
    case edit(ExpenseCategory)
    
    var id: String {
        switch self {
        case .new(_): return "new"
        case .edit(let category): return category.persistentModelID.entityName
        }
    }
    
    static func == (lhs: ActiveCategorySheet, rhs: ActiveCategorySheet) -> Bool {
        switch (lhs, rhs) {
        case (.new(let l), .new(let r)): 
            return l.name == r.name && l.iconName == r.iconName && l.hexColor == r.hexColor && l.isDefault == r.isDefault && l.sortOrder == r.sortOrder
        case (.edit(let l), .edit(let r)): return l.id == r.id
        default: return false
        }
    }
}

enum NotificationDay: CaseIterable {
    case oneWeekBefore, threeDaysBefore, oneDayBefore, onDay, overdue
    
    var description: String {
        switch self {
        case .oneWeekBefore:
            return String(localized: "One week before due")
        case .threeDaysBefore:
            return String(localized: "Three days before due")
        case .oneDayBefore:
            return String(localized: "The day before due")
        case .onDay:
            return String(localized: "When due")
        case .overdue:
            return String(localized: "When overdue")
        }
    }
}

// MARK: - Frequency Formatting

extension FrequencyUnit {
    /// Returns the properly capitalized and pluralized form of the frequency unit.
    func displayName(for value: Int16) -> String {
        let singular = value == 1
        switch self {
        case .day:
            return singular ? String(localized: "Day") : String(localized: "Days")
        case .week:
            return singular ? String(localized: "Week") : String(localized: "Weeks")
        case .month:
            return singular ? String(localized: "Month") : String(localized: "Months")
        case .year:
            return singular ? String(localized: "Year") : String(localized: "Years")
        }
    }
    
    /// Returns the appropriate range of values for this frequency unit.
    var valueRange: ClosedRange<Int16> {
        switch self {
        case .day:
            return 1...365
        case .week:
            return 1...52
        case .month:
            return 1...12
        case .year:
            return 1...100
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .year: return 0
        case .month: return 1
        case .week: return 2
        case .day: return 3
        }
    }
}
