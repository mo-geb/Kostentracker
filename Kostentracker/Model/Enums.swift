//
//  Enums.swift
//  Kostentracker
//

enum FrequencyUnit: String, Codable, CaseIterable {
    case day, week, month, year
}

enum SortOption: String, CaseIterable, Identifiable {
    case dateDescending = "Newest First"
    case dateAscending = "Oldest First"
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
    case recent = "Recent (Last 30 Days)"
    
    var id: Self { self }
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
}
