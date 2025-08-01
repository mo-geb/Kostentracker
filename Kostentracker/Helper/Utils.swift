import Foundation
import SwiftUI
import SwiftData

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

func unsetAllDefaultCategories(in context: ModelContext) {
    let descriptor = FetchDescriptor<ExpenseCategory>()
    if let allCategories = try? context.fetch(descriptor) {
        for cat in allCategories {
            cat.isDefault = false
        }
    }
}
