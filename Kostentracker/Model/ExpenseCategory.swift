//
//  ExpenseCategory.swift
//  Kostentracker
//

import SwiftUI
import SwiftData
import UIKit

@Model
final class ExpenseCategory: Identifiable {
    @Attribute(.unique) var name: String
    var iconName: String
    var hexColor: String
    var isDefault: Bool = false
    var sortOrder: Int = 0
    
    @Relationship(deleteRule: .cascade, inverse: \Expense.category) var expenses: [Expense]?
    
    init(name: String, iconName: String, color: Color, isDefault: Bool = false, sortOrder: Int = 0) {
        self.name = name
        self.iconName = iconName
        self.hexColor = color.toHex() ?? "000000"
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
    
    /// A computed property to easily get the SwiftUI Color.
    var color: Color {
        Color(hex: hexColor)
    }
}

extension Color {
    func toHex() -> String? {
        // Try to get components from cgColor
        if let components = cgColor?.components, components.count >= 3 {
            let r = Float(components[0])
            let g = Float(components[1])
            let b = Float(components[2])
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
        
        // Fallback for system colors - convert to a known color space
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return String(format: "%02lX%02lX%02lX", 
                         lroundf(Float(red) * 255), 
                         lroundf(Float(green) * 255), 
                         lroundf(Float(blue) * 255))
        }
        
        return nil
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Category Management

extension ExpenseCategory {
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
}
