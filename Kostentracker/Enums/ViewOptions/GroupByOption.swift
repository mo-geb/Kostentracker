import Foundation

enum GroupByOption: String, CaseIterable, Identifiable {
    case none, categories

    var id: Self { self }

    var localizedName: String {
        switch self {
        case .none:       return String(localized: "None")
        case .categories: return String(localized: "Categories")
        }
    }
}
