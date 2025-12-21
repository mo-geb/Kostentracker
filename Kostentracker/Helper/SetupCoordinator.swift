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
        createDefaultsSafe()
    }
    
    // MARK: - Private Helper Methods
    
    private func createDefaultsSafe() {
        let defaultCategory = ExpenseCategory.createDefault()
        context.insert(defaultCategory)
        
        try? context.save()
    }
}
