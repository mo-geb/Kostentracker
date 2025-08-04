import Foundation

enum CategoryChart: LocalizedStringResource, CaseIterable, Identifiable {
    case barChart = "Bar"
    case pieChart = "Pie"
    
    var id: Self { self }
}
