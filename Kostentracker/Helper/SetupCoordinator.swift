import Foundation
import SwiftData

@MainActor
final class SetupCoordinator {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// The main entry point to run all necessary setup tasks.
    func run() {
        createDefaultCategoriesIfNeeded()
    }
    
    // MARK: - Private Helper Methods
    
    private func createDefaultCategoriesIfNeeded() {
        let defaults = UserDefaults.standard
        
        guard !defaults.bool(forKey: "isInitialSetupComplete") else {
            return
        }

        Task {
            try? await Task.sleep(for: .seconds(3))
            
            let fetchDescriptor = FetchDescriptor<ExpenseCategory>()
            do {
                let count = try context.fetchCount(fetchDescriptor)
                if count == 0 {
                    print("No categories found after delay. Creating default set...")
                    let defaultCategory = ExpenseCategory.createDefault()
                    context.insert(defaultCategory)
                    print("Default categories created successfully.")
                } else {
                    print("Categories found from iCloud. Skipping default creation.")
                }
            } catch {
                print("Failed to fetch category count: \(error)")
            }
            
            defaults.set(true, forKey: "isInitialSetupComplete")
        }
    }
}
