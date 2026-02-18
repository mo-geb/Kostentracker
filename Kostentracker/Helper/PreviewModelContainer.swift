import SwiftUI
import SwiftData

struct PreviewModelContainer: PreviewModifier {
    
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(for: Expense.self, ExpenseCategory.self, ExpenseAccount.self)
        
        try? container.mainContext.delete(model: Expense.self)
        try? container.mainContext.delete(model: ExpenseCategory.self)
        try? container.mainContext.delete(model: ExpenseAccount.self)
        
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
    }
}
