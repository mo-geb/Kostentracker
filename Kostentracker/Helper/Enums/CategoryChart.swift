import Foundation

enum CategoryChart: String, CaseIterable, Identifiable {
    case barChart, pieChart
    
    var id: Self { self }
    
    var localizedName: String {
        switch self {
        case .barChart:
            return String(localized: "Bar")
        case .pieChart:
            return String(localized: "Pie")
        }
    }
}
