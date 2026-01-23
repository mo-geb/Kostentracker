import SwiftUI
import SwiftData

@main
struct KostentrackerApp: App {
    let modelContainer: ModelContainer
    
    @StateObject private var ui = UIState.shared
    @StateObject private var userSettings = UserSettings.shared
    
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
                .environmentObject(ui)
                .environmentObject(userSettings)
       }
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    MainTabView()
        .environmentObject(UIState())
        .environmentObject(UserSettings())
}
