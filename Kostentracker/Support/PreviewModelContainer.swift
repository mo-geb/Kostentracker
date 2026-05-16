import SwiftUI
import SwiftData

struct PreviewModelContainer: PreviewModifier {
    
    static func makeSharedContext() async throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Expense.self, ExpenseCategory.self, ExpenseAccount.self,
            configurations: config
        )

        SampleData.categories.forEach { container.mainContext.insert($0) }
        SampleData.accounts.forEach { container.mainContext.insert($0) }
        SampleData.expenses.forEach { container.mainContext.insert($0) }
        
        return container
    }
    
    func body(content: Content, context: ModelContainer) -> some View {
        content
            .modelContainer(context)
            .environment(UIState())
            .environment(UserSettings())
            .environment(StoreManager())
    }
}
