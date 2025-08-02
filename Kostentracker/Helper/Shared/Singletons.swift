import Foundation
import SwiftUI

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("currencyCode") var currencyCode: String = "EUR"
}

final class UIState: ObservableObject {
    static let shared = UIState()
    
    @Published var showingSettings: Bool = false
    
    @Published var selectedFilter: FilterOption = .nonZero
    @Published var selectedSort: SortOption = .amountDescending
    @Published var selectedGroupBy: GroupByOption = .categories
    @Published var selectedViewMode: ViewMode = .normal
    
    @Published var activeExpenseSheet: ActiveExpenseSheet?
}
