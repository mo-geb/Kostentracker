//
//  AppSetupCoordinator.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

/// A class responsible for handling all one-time setup tasks when the app launches.
/// This includes data migration, creating default data, etc.
@MainActor
final class AppSetupCoordinator {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// The main entry point to run all necessary setup tasks.
    func run() {
        createDefaultCategoriesIfNeeded()
    }
    
    // MARK: - Private Helper Methods
    
    /// Creates a set of default categories if the database is empty.
    private func createDefaultCategoriesIfNeeded() {
        // Check if any categories already exist.
        let fetchDescriptor = FetchDescriptor<ExpenseCategory>()
        do {
            let count = try context.fetchCount(fetchDescriptor)
            if count > 0 {
                return // Categories already exist, no need to create defaults
            }
        } catch {
            print("Failed to fetch category count: \(error)")
            return
        }
        
        print("No categories found. Creating default set...")
        context.insert(ExpenseCategory.createDefault())
        print("Default categories created successfully.")
    }
}
