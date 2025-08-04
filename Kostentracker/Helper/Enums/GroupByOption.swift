import Foundation

enum GroupByOption: LocalizedStringResource, CaseIterable, Identifiable {
    case none = "None"
    case categories = "Categories"
    case frequencyUnit = "Frequency"
    
    var id: Self { self }
}
