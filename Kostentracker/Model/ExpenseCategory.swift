import SwiftUI
import SwiftData
import UIKit

@Model
final class ExpenseCategory: Identifiable {
    var name: String = ""
    var iconName: String = ""
    var hexColor: String = ""
    var isDefault: Bool = false
    var sortOrder: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \Expense.category) var expenses: [Expense]?
    
    /// A computed property to easily get the SwiftUI Color.
    var color: Color {
        Color(hex: hexColor)
    }
    
    /// Create Category based on draft
    init(from draft: CategoryDraft) {
        self.name = draft.name
        self.iconName = draft.iconName
        self.hexColor = draft.hexColor
        self.isDefault = draft.isDefault
        self.sortOrder = draft.sortOrder
    }
    
    /// Update based on draft
    func update(from draft: CategoryDraft) {
        self.name = draft.name
        self.iconName = draft.iconName
        self.hexColor = draft.hexColor
        self.isDefault = draft.isDefault
        self.sortOrder = draft.sortOrder
    }
}

extension ExpenseCategory {
    static func getDefault(with context: ModelContext) -> ExpenseCategory {
        let descriptor = FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.isDefault })
        if let defaultCategory = try? context.fetch(descriptor).first {
            return defaultCategory
        }
        return createDefault()
    }
    
    static func createDefault() -> ExpenseCategory {
        return ExpenseCategory(from: CategoryDraft(name: String(localized: "Other"), iconName: "tag", color: .gray, isDefault: true))
    }
    
    /// Safely deletes a category by reassigning its expenses to the default category.
    /// This method ensures no expenses are orphaned when a category is deleted.
    func deleteSafely(from context: ModelContext) {
        guard !isDefault else { return }
        do {
            let descriptor = FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.isDefault })
            guard let defaultCategory = try context.fetch(descriptor).first else {
                print("Could not find default category. Aborting delete.")
                return
            }
            if let expensesToReassign = expenses {
                for expense in expensesToReassign {
                    expense.category = defaultCategory
                }
            }
            context.delete(self)
            try context.save()
        } catch {
            print("Failed to delete category: \(error)")
        }
    }
    
    static func resetDefaultCategories(in context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseCategory>()
        if let allCategories = try? context.fetch(descriptor) {
            for cat in allCategories {
                cat.isDefault = false
            }
        }
    }
}

// MARK: - Category Draft struct for creating and editing Categories

struct CategoryDraft {
    var name: String
    var iconName: String
    var hexColor: String
    var isDefault: Bool
    var sortOrder: Int
    
    init(name: String, iconName: String, color: Color, isDefault: Bool = false, sortOrder: Int = 0) {
        self.name = name
        self.iconName = iconName
        self.hexColor = color.toHex() ?? "000000"
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
    
    init(from category: ExpenseCategory) {
        self.name = category.name
        self.iconName = category.iconName
        self.hexColor = category.hexColor
        self.isDefault = category.isDefault
        self.sortOrder = category.sortOrder
    }
    
    static func createNew(sortOrder: Int = 0) -> CategoryDraft {
        CategoryDraft(
                name: "",
                iconName: "tag",
                color: .blue,
                isDefault: false,
                sortOrder: sortOrder
        )
    }
}
