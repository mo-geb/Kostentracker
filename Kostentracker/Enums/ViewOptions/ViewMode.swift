import Foundation

enum ViewMode: String, CaseIterable, Identifiable {
    case normal, compact
    
    var id: Self { self }
    
    var localizedName: String {
        switch self {
        case .normal:  return String(localized: "Normal")
        case .compact: return String(localized: "Compact")
        }
    }

    var iconName: String {
        switch self {
        case .normal:  return "list.bullet"
        case .compact: return "rectangle.compress.vertical"
        }
    }
}
