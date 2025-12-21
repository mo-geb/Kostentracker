import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case amountDescending, amountAscending, title
    
    var id: Self { self }
    
    var localizedName: String {
        switch self {
        case .amountDescending:
            return String(localized: "Amount (High to Low)")
        case .amountAscending:
            return String(localized: "Amount (Low to High)")
        case .title:
            return String(localized: "Title (A-Z)")
        }
    }
}
