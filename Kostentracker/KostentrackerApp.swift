import SwiftUI
import SwiftData

@main
struct KostentrackerApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
       }
        .modelContainer(for: Expense.self)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Expense.self, inMemory: true)
}
