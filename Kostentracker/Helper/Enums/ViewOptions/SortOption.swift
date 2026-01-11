import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case amountDescending, amountAscending, title
    
    var id: Self { self }
    
    var localizedName: String {
        switch self {
        case .amountDescending:
            return String(localized: "Amount")
        case .amountAscending:
            return String(localized: "Amount")
        case .title:
            return String(localized: "Title")
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .amountDescending:
            return String(localized: "High to Low")
        case .amountAscending:
            return String(localized: "Low to High")
        case .title:
            return String(localized: "A-Z")
        }
    }
}
