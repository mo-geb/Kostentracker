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

enum SortOption: String, CaseIterable, Identifiable {
    case amountDescending = "Amount (High to Low)"
    case amountAscending = "Amount (Low to High)"
    case title = "Title (A-Z)"
    
    var id: Self { self }
}

enum CostPeriod: String, CaseIterable, Identifiable {
    case yearly = "Yearly"
    case monthly = "Monthly"
    case weekly = "Weekly"
    case daily = "Daily"
    
    var id: Self { self }
}

enum FilterOption: String, CaseIterable, Identifiable {
    case all = "All Expenses"
    case nonZero = "Non-Zero Cost"
    case upcoming = "Upcoming (Next 30 Days)"
    
    var id: Self { self }
}

enum GroupByOption: String, CaseIterable, Identifiable {
    case none = "None"
    case categories = "Categories"
    case frequencyUnit = "Frequency"
    
    var id: Self { self }
}

enum ViewMode: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case compact = "Compact"
    
    var id: Self { self }
}

enum FocusedField: Hashable {
    case expenseDetailTitle
    case expenseDetailAmount
    case expenseDetailNotes
}

enum ActiveSheet: Identifiable, Equatable {
    case view(Expense)
    case new(Expense)
    case edit(Expense)
    
    var id: PersistentIdentifier {
        switch self {
        case .view(let expense): return expense.persistentModelID
        case .new(let expense): return expense.persistentModelID
        case .edit(let expense): return expense.persistentModelID
        }
    }
    
    static func == (lhs: ActiveSheet, rhs: ActiveSheet) -> Bool {
        switch (lhs, rhs) {
        case (.view(let l), .view(let r)): return l.id == r.id
        case (.new(let l), .new(let r)): return l.id == r.id
        case (.edit(let l), .new(let r)): return l.id == r.id
        default: return false
        }
    }
}

// MARK: - Frequency Formatting

extension FrequencyUnit {
    /// Returns the properly capitalized and pluralized form of the frequency unit.
    func displayName(for value: Int16) -> String {
        let base = rawValue.capitalized
        return value == 1 ? base : base + "s"
    }
    
    /// Returns the complete frequency string (e.g., "Every Month" or "Every 2 Months").
    static func formatFrequency(value: Int16, unit: FrequencyUnit) -> String {
        if value == 1 {
            return "Every \(unit.rawValue)"
        } else {
            return "Every \(value) \(unit.rawValue)s"
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
