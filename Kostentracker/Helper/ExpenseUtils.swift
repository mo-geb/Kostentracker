//
//  ExpenseUtils.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 08.07.25.
//

import Foundation

struct ExpenseUtils {
    static func applyFilters(_ expenses: [Expense], filter: FilterOption) -> [Expense] {
        var filtered = expenses
        switch filter {
        case .all:
            break
        case .nonZero:
            filtered = filtered.filter { $0.yearlyCost > 0 }
        case .recent:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= thirtyDaysAgo }
        }
        return filtered
    }
}
