//
//  ExpenseViewModel.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 30.06.25.
//


import Combine
import Foundation

class ExpenseViewModel: ObservableObject {
    @Published var expense: ExpenseEntity
    
    init(expense: ExpenseEntity) {
        self.expense = expense
    }
    
    var id: UUID { expense.wrappedId }
    
    var title: String {
        get { expense.wrappedTitle }
        set { expense.title = newValue }
    }
    
    var amount: Double {
        get { expense.amount }
        set { expense.amount = newValue }
    }
    
    var frequencyUnit: FrequencyUnit {
        get { expense.frequencyUnit }
        set { expense.frequencyUnit = newValue }
    }
    
    var frequencyValue: Int32 {
        get { expense.frequencyValue }
        set { expense.frequencyValue = newValue }
    }
    
    var date: Date {
        get { expense.wrappedDate }
        set { expense.date = newValue }
    }
    
    var category: Category {
        get { expense.category }
        set { expense.category = newValue }
    }
    
    var notes: String {
        get { expense.wrappedNotes }
        set { expense.notes = newValue }
    }
}
