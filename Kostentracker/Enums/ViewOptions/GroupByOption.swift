import Foundation

enum GroupByOption: String, CaseIterable, Identifiable {
    case none, categories, frequency
    
    var id: Self { self }
    
    var localizedName: String {
        switch self {
        case .none:
            return String(localized: "None")
        case .categories:
            return String(localized: "Categories")
        case .frequency:
            return String(localized: "Frequency")
        }
    }
}
