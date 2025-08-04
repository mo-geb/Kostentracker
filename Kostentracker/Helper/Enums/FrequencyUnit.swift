import Foundation

enum FrequencyUnit: String, Codable, CaseIterable {
    case day, week, month, year
}

extension FrequencyUnit {
    var periodName: LocalizedStringResource {
        switch self {
        case .year: return "Yearly"
        case .month: return "Monthly"
        case .week: return "Weekly"
        case .day: return "Daily"
        }
    }
    
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
    
    /// Returns the properly capitalized and pluralized form of the frequency unit.
    func displayText(for value: Int16) -> String {
        let singular = value == 1
        switch self {
        case .day:
            return singular ? String(localized: "Every day") : String(localized: "Every \(value) days")
        case .week:
            return singular ? String(localized: "Every week") : String(localized: "Every \(value) weeks")
        case .month:
            return singular ? String(localized: "Every month") : String(localized: "Every \(value) months")
        case .year:
            return singular ? String(localized: "Every year") : String(localized: "Every \(value) years")
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
