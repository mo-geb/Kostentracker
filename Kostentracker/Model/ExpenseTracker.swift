//
//  ExpenseTracker.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 29.06.25.
//

import CoreData

class ExpenseTracker: ObservableObject {
    let viewContext = PersistenceController.shared.container.viewContext

    @Published var expenses: [ExpenseEntity] = []

    init() {
        fetchExpenses()
    }

    func fetchExpenses() {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)]

        do {
            expenses = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch expenses: \(error)")
        }
    }

    func addExpense(title: String, amount: Double, frequencyUnit: String, frequencyValue: Int32, date: Date, category: String, notes: String) {
        let newExpense = ExpenseEntity(context: viewContext)
        newExpense.id = UUID()
        newExpense.title = title
        newExpense.amount = amount
        
        if let unit = FrequencyUnit(rawValue: frequencyUnit) {
            newExpense.frequencyUnit = unit
        } else {
            newExpense.frequencyUnit = .months
        }
        
        newExpense.frequencyValue = frequencyValue
        newExpense.date = date
        
        if let cat = Category(rawValue: category) {
            newExpense.category = cat
        } else {
            newExpense.category = .other
        }
        
        newExpense.notes = notes

        save()
        fetchExpenses()
    }


    func updateExpense(_ expense: ExpenseEntity) {
        save()
        fetchExpenses()
    }

    func deleteExpense(_ expense: ExpenseEntity) {
        viewContext.delete(expense)
        save()
        fetchExpenses()
    }

    private func save() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
