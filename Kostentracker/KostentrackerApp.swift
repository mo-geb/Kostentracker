import SwiftUI
import SwiftData

@main
struct KostentrackerApp: App {
    let modelContainer: ModelContainer
    
    @State private var ui = UIState()
    @State private var userSettings = UserSettings()
    @State private var store = StoreManager()

    init() {
        do {
            modelContainer = try ModelContainer(for: Expense.self, ExpenseCategory.self, ExpenseAccount.self)
            let context = modelContainer.mainContext
            
            let setupCoordinator = SetupCoordinator(context: context)
            setupCoordinator.run()
            
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(modelContainer)
                .environment(ui)
                .environment(userSettings)
                .environment(store)
                .task { store.start() }
       }
    }
}
