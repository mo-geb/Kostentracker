import Foundation

enum SortOption: LocalizedStringResource, CaseIterable, Identifiable {
    case amountDescending = "Amount (High to Low)"
    case amountAscending = "Amount (Low to High)"
    case title = "Title (A-Z)"
    
    var id: Self { self }
}
