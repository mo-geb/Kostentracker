import Foundation

enum FilterOption: String, CaseIterable, Identifiable {
    case all, nonZero, upcoming
    
    var id: Self { self }
    
    var localizedName: String {
        switch self {
        case .all: return String(localized: "All Expenses")
        case .nonZero: return String(localized: "Only Active (Cost not zero")
        case .upcoming: return String(localized: "Upcoming (Next 30 Days)")
        }
    }
}
