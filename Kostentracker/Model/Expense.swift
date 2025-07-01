//
//  Expense.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 30.06.25.
//

import Foundation
import SwiftData

@Model
class Expense: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var amount: Double = 0
    var frequencyUnit: FrequencyUnit = FrequencyUnit.months
    var frequencyValue: Int16 = 1
    var date: Date = Date()
    var category: Category = Category.other
    var notes: String = ""
    
    init(title: String, amount: Double, frequencyUnit: FrequencyUnit, frequencyValue: Int16, date: Date, category: Category, notes: String) {
        self.title = title
        self.amount = amount
        self.frequencyUnit = frequencyUnit
        self.frequencyValue = frequencyValue
        self.date = date
        self.category = category
        self.notes = notes
    }
}
