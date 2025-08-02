import Foundation

final class UIState: ObservableObject {
    static let shared = UIState()
    
    @Published var showingSettings: Bool = false
    
    @Published var selectedFilter: FilterOption = .nonZero
    @Published var selectedSort: SortOption = .amountDescending
    @Published var selectedGroupBy: GroupByOption = .categories
    @Published var selectedViewMode: ViewMode = .normal
    
    @Published var activeExpenseSheet: ActiveExpenseSheet?
}
