import Foundation

enum FilterOption: String, CaseIterable, Identifiable {
    case all, upcoming, active
    
    var id: Self { self }
    
    var localizedName: String {
        switch self {
        case .all: return String(localized: "All Expenses")
        case .active: return String(localized: "Only active")
        case .upcoming: return String(localized: "Upcoming")
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .all: return String(localized: "")
        case .active: return String(localized: "Hide inactive")
        case .upcoming: return String(localized: "Only next 30 Days")
        }
    }
}
