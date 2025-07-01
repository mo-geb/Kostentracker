//
//  ExpenseDetailView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct ExpenseDetailView: View {
    // MARK: - Properties
    
    @Bindable var expense: Expense
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing: Bool
    var onSave: (() -> Void)?
    
    init(expense: Expense, isEditingInitial: Bool = false, onSave: (() -> Void)? = nil) {
        self._expense = Bindable(wrappedValue: expense)
        self._isEditing = State(initialValue: isEditingInitial)
        self.onSave = onSave
    }
    
    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                titleSection
                
                detailsSection
                
                if isEditing {
                    deleteButton
                } else {
                    statisticsSection
                }
            }
        }
        .toolbar {
            toolbarContent
        }
    }

    // MARK: - View Components
    
    @ViewBuilder
    private var titleSection: some View {
        if isEditing {
            TextField("Title", text: $expense.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        } else {
            Text(expense.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            row(title: "Amount") {
                if isEditing {
                    TextField("Amount", value: $expense.amount, format: .currency(code: "EUR"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .fixedSize()
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                } else {
                    Text(expense.amount, format: .currency(code: "EUR"))
                }
            }
            
            row(title: "Frequency") {
                if isEditing {
                    HStack {
                        TextField("Value", value: Binding(
                            get: { Int(expense.frequencyValue) },
                            set: { expense.frequencyValue = Int16($0) }
                        ), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .fixedSize()
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Picker("Unit", selection: $expense.frequencyUnit) {
                            ForEach(FrequencyUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue.capitalized).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } else {
                    Text("\(expense.frequencyValue) \(expense.frequencyUnit.rawValue.capitalized)")
                }
            }
            
            row(title: "Date") {
                if isEditing {
                    DatePicker("", selection: $expense.date, displayedComponents: [.date])
                        .labelsHidden()
                } else {
                    Text(expense.date, style: .date)
                }
            }
            
            row(title: "Category") {
                if isEditing {
                    HStack {
                        Picker("Category", selection: $expense.category) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Label(category.rawValue.capitalized, systemImage: category.iconName).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } else {
                    Label(expense.category.rawValue.capitalized, systemImage: expense.category.iconName)
                }
            }
            
            // Notes section
            VStack(alignment: .leading) {
                Text("Notes").font(.headline)
                if isEditing {
                    TextEditor(text: $expense.notes)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .frame(minHeight: 100)
                } else if !expense.notes.isEmpty {
                    Text(expense.notes)
                } else {
                    Text("No notes provided.")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        VStack {
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Statistics")
                    .font(.headline)

                let yearlyCost = calculateYearlyCost(
                    amount: expense.amount,
                    frequencyValue: Int(expense.frequencyValue),
                    frequencyUnit: expense.frequencyUnit
                )
                let monthlyCost = yearlyCost / 12
                let weeklyCost = yearlyCost / 52

                Text("Yearly: \(yearlyCost, format: .currency(code: "EUR"))")
                Text("Monthly: \(monthlyCost, format: .currency(code: "EUR"))")
                Text("Weekly: \(weeklyCost, format: .currency(code: "EUR"))")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
    
    @ViewBuilder
    private var deleteButton: some View {
        Button(role: .destructive) {
            context.delete(expense)
            dismiss()
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(.red)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if isEditing {
                Button {
                    // Reload from persistent store if cancel pressed
                    context.rollback()
                    isEditing = false
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            } else {
                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "chevron.down")
                }
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            if isEditing {
                Button {
                    do {
                        try context.save()
                        isEditing = false
                        onSave?()
                    } catch {
                        print("Failed to save expense: \(error)")
                    }
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .tint(.green)
            } else {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    // A generic row builder to reduce duplication of HStack, Spacer, etc.
    @ViewBuilder
    private func row<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
            Spacer()
            content()
        }
    }

    // MARK: - Logic
    
    private func calculateYearlyCost(amount: Double, frequencyValue: Int, frequencyUnit: FrequencyUnit) -> Double {
        guard frequencyValue > 0 else { return 0 }
        switch frequencyUnit {
        case .days:
            return amount * (365.0 / Double(frequencyValue))
        case .weeks:
            return amount * (52.0 / Double(frequencyValue))
        case .months:
            return amount * (12.0 / Double(frequencyValue))
        case .years:
            return amount / Double(frequencyValue)
        }
    }
}

#Preview("Dark Mode") {
    // Create a sample expense for the preview
    let sampleExpense = Expense(title: "Netflix Subscription", amount: 15.99, frequencyUnit: .months, frequencyValue: 1, date: Date(), category: .subscription, notes: "Premium plan with 4 screens.")
    
    NavigationStack {
        ExpenseDetailView(expense: sampleExpense)
    }
    .preferredColorScheme(.dark) // <-- This forces the preview to be dark
}

