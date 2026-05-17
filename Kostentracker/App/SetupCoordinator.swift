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
        ExpenseCategory.consolidateDefaultCategories(in: context)
        ExpenseCategory.deleteEmptyDefaultCategories(in: context)
        ExpenseAccount.consolidateDefaultAccounts(in: context)
    }
}
