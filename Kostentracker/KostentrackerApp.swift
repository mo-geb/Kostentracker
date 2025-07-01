import SwiftUI

@main
struct KostentrackerApp: App {
    @StateObject private var expenseTracker = ExpenseTracker()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(expenseTracker)
        }
    }
}

struct KostentrackerApp_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(ExpenseTracker())
    }
}
