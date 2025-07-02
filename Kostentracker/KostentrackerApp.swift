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
    do {
        // 1. Create a configuration for an in-memory database.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        // 2. Create the temporary container.
        let container = try ModelContainer(for: Expense.self, configurations: config)
        
        // 3. This is the magic: Insert all your sample expenses into the container.
        PreviewSampleData.expenses.forEach {
            container.mainContext.insert($0)
        }
        
        // 4. Return your view and tell it to use this pre-filled container.
        return MainTabView()
            .modelContainer(container)
        
    } catch {
        // If creating the container fails, show an error.
        return Text("Failed to create preview container: \(error.localizedDescription)")
    }
}
