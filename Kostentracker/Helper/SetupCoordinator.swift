import Foundation
import SwiftData

@MainActor
final class SetupCoordinator {
    
    private let context: ModelContext
    private let defaults = UserDefaults.standard

    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// The main entry point to run all necessary setup tasks.
    func run() {
        // Default cleanup
        let defaultCleanupKey = "didPerformDefaultCategoryCleanup_v1"
        if !defaults.bool(forKey: defaultCleanupKey) {
            consolidateDefaultCategories(in: context)
            defaults.set(true, forKey: defaultCleanupKey)
        }
    }

    // MARK: - Private Helper Methods
    
    private func consolidateDefaultCategories(in context: ModelContext) {
            let descriptor = FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.isDefault })
            
            do {
                let defaultCategories = try context.fetch(descriptor)

                guard defaultCategories.count > 1 else { return }
                
                print("Found \(defaultCategories.count) default categories. Starting consolidation...")
                
                let sortedDefaults = defaultCategories.sorted {
                    ($0.expenses?.count ?? 0) > ($1.expenses?.count ?? 0)
                }
                
                let survivor = sortedDefaults[0]
                let duplicates = sortedDefaults.dropFirst()
                
                for duplicate in duplicates {
                    print("Merging duplicate default category: \(duplicate.name) with \(duplicate.expenses?.count ?? 0) expenses")
                    
                    if let expensesToMove = duplicate.expenses {
                        // Create a copy of the array to avoid mutation issues during iteration
                        let expensesArray = Array(expensesToMove)
                        for expense in expensesArray {
                            expense.category = survivor
                        }
                    }
                    
                    context.delete(duplicate)
                }
                survivor.isDefault = true
                
                try context.save()
                print("Consolidation complete. One default category remains.")
                
            } catch {
                print("Failed to consolidate default categories: \(error)")
            }
        }
}
