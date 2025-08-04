import Foundation

enum FilterOption: LocalizedStringResource, CaseIterable, Identifiable {
    case all = "All Expenses"
    case nonZero = "Non-Zero Cost"
    case upcoming = "Upcoming (Next 30 Days)"
    
    var id: Self { self }
}
