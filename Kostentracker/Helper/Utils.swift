import Foundation
import SwiftUI
import SwiftData

final class UIState: ObservableObject {
    static let shared = UIState()
    
    @Published var showingSettings: Bool = false
    
    @Published var selectedFilter: FilterOption = .nonZero
    @Published var selectedSort: SortOption = .amountDescending
    @Published var selectedGroupBy: GroupByOption = .categories
    @Published var selectedViewMode: ViewMode = .normal
}

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("currencyCode") var currencyCode: String = "EUR"
}


struct Utils {
    static func applyFilters(_ expenses: [Expense], filter: FilterOption) -> [Expense] {
        var filtered = expenses
        switch filter {
        case .all:
            break
        case .nonZero:
            filtered = filtered.filter { $0.yearlyCost > 0 }
        case .upcoming:
            let nextThirtyDays = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date <= nextThirtyDays }
        }
        return filtered
    }
    
    static func resetDefaultCategories(in context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseCategory>()
        if let allCategories = try? context.fetch(descriptor) {
            for cat in allCategories {
                cat.isDefault = false
            }
        }
    }
}

struct EmptyExpensesView: View {
    var body: some View {
        ContentUnavailableView(
            "No Expenses",
            systemImage: "tray",
            description: Text("Tap the + button to add your first expense.")
        )
    }
}

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }

    var fullVersionString: String {
        "v\(appVersion) (Build \(buildNumber))"
    }
}
