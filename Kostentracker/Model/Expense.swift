//
//  Expense.swift
//  Kostentracker
//

import Foundation
import SwiftData

@Model
class Expense: Identifiable {
    var title: String = ""
    var amount: Double = 0
    var frequencyUnit: FrequencyUnit = FrequencyUnit.month
    var frequencyValue: Int16 = 1
    var date: Date = Date()
    var category: ExpenseCategory = ExpenseCategory(name: "Other", iconName: "questionmark", color: .gray)
    var notes: String = ""
    @Attribute(.externalStorage) var customImageData: Data?
    
    init(title: String, amount: Double, frequencyUnit: FrequencyUnit, frequencyValue: Int16, date: Date, category: ExpenseCategory, notes: String, customImageData: Data? = nil) {
        self.title = title
        self.amount = amount
        self.frequencyUnit = frequencyUnit
        self.frequencyValue = frequencyValue
        self.date = date
        self.category = category
        self.notes = notes
        self.customImageData = customImageData
    }
    
    static func createNew(with context: ModelContext) -> Expense {
        let defaultCategory: ExpenseCategory?
        do {
            let descriptor = FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.isDefault })
            defaultCategory = try context.fetch(descriptor).first
        } catch {
            print("Failed to fetch default category for new expense: \(error)")
            defaultCategory = nil
        }
        
        // Create the new expense.
        return Expense(title: "", amount: 0, frequencyUnit: .month, frequencyValue: 1, date: Date(), category: defaultCategory ?? ExpenseCategory(name: "Other", iconName: "tag", color: .gray, isDefault: true), notes: "")
    }
}

extension Expense {
    var yearlyCost: Double {
        let frequencyValue = Double(self.frequencyValue)
        guard frequencyValue > 0 else { return 0 }
        switch self.frequencyUnit {
        case .day: return self.amount * (365.0 / frequencyValue)
        case .week: return self.amount * (52.0 / frequencyValue)
        case .month: return self.amount * (12.0 / frequencyValue)
        case .year: return self.amount / frequencyValue
        }
    }
}

