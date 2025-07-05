//
//  KostentrackerApp.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

@main
struct KostentrackerApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Expense.self, ExpenseCategory.self)
            let context = modelContainer.mainContext
            
            #if DEBUG
            print("Entered App in DEBUG... Deleting models")
            try? context.delete(model: Expense.self)
            try? context.delete(model: ExpenseCategory.self)

            UserDefaults.standard.removeObject(forKey: "hasCreatedDefaultCategories")
            #endif
            
            let setupCoordinator = AppSetupCoordinator(context: modelContainer.mainContext)
            setupCoordinator.run()
            
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
       }
        .modelContainer(for: Expense.self)
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: Expense.self, ExpenseCategory.self)
        let context = container.mainContext
        
        UserDefaults.standard.removeObject(forKey: "hasCreatedDefaultCategories")
        
        PreviewSampleData.categories.forEach {
            container.mainContext.insert($0)
        }
        
        PreviewSampleData.expenses.forEach {
            container.mainContext.insert($0)
        }
        
        return MainTabView()
            .modelContainer(container)
        
    } catch {
        return Text("Failed to create preview container: \(error.localizedDescription)")
    }
}
