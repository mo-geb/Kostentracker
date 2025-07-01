//
//  ExpenseDetailView.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 30.06.25.
//

import SwiftUI

struct ExpenseDetailView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tracker: ExpenseTracker
    
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                if isEditing {
                    TextField("Title", text: Binding(
                        get: { viewModel.title },
                        set: { viewModel.title = $0 }
                    ))
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                } else {
                    Text(viewModel.title)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    // Amount
                    HStack {
                        Text("Amount")
                        Spacer()
                        if isEditing {
                            TextField("Amount", value: Binding(
                                get: { viewModel.amount },
                                set: { viewModel.amount = $0 }
                            ), format: .currency(code: "EUR"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .fixedSize()
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        } else {
                            Text(viewModel.amount, format: .currency(code: "EUR"))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    // Frequency Value
                    HStack {
                        Text("Frequency")
                        Spacer()
                        if isEditing {
                            TextField("Frequency", value: Binding(
                                get: { Int(viewModel.frequencyValue) },
                                set: { viewModel.frequencyValue = Int32($0) }
                            ), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .fixedSize()
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            Picker("Frequency Unit", selection: Binding(
                                get: { viewModel.frequencyUnit },
                                set: { viewModel.frequencyUnit = $0 }
                            )) {
                                ForEach(FrequencyUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue.capitalized).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                        } else {
                            Text("\(viewModel.frequencyValue)")
                                .multilineTextAlignment(.trailing)
                            
                            Text(viewModel.frequencyUnit.rawValue.capitalized)
                        }
                    }
                    
                    // Date
                    HStack {
                        Text("Date")
                        Spacer()
                        if isEditing {
                            DatePicker("", selection: Binding(
                                get: { viewModel.date },
                                set: { viewModel.date = $0 }
                            ), displayedComponents: [.date])
                            .labelsHidden()
                        } else {
                            Text(viewModel.date, style: .date)
                        }
                    }
                    
                    // Notes
                    ZStack(alignment: .topLeading) {
                        if isEditing {
                            TextEditor(text: Binding(
                                get: { viewModel.notes },
                                set: { viewModel.notes = $0 }
                            ))
                            .padding(4)
                            .cornerRadius(8)
                            .frame(minHeight: 100)
                        } else {
                            Text(viewModel.notes.isEmpty ? "" : viewModel.notes)
                        }
                    }
                }
                .padding()
                
                // Hidden elements
                if isEditing {
                    // Delete Button
                    Button(role: .destructive, action : {
                        dismiss()
                        tracker.deleteExpense(viewModel.expense)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                } else {
                    // Statistics
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Statistics")
                            .font(.headline)
                        
                        let yearlyCost = calculateYearlyCost(amount: viewModel.amount, frequencyValue: Int(viewModel.frequencyValue), frequencyUnit: viewModel.frequencyUnit)
                        let monthlyCost = yearlyCost / 12
                        let weeklyCost = yearlyCost / 52
                        
                        Text("Yearly: \(yearlyCost, format: .currency(code: "EUR"))")
                        Text("Monthly: \(monthlyCost, format: .currency(code: "EUR"))")
                        Text("Weekly: \(weeklyCost, format: .currency(code: "EUR"))")
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button(action : {
                            moc.rollback()
                            isEditing = false
                        }) {
                            Label("Discard", systemImage: "xmark")
                        }
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button(action : {
                            do {
                                try moc.save()
                                isEditing = false
                            } catch {
                                print("Failed to save: expense: title=\(viewModel.title), amount=\(viewModel.amount), date=\(viewModel.date), ", error)
                            }
                        }) {
                            Label("Save", systemImage: "checkmark")
                        }
                        .tint(.green)
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
        }
    }
    
    // Helper function to calculate yearly cost based on frequency
    private func calculateYearlyCost(amount: Double, frequencyValue: Int, frequencyUnit: FrequencyUnit) -> Double {
        switch frequencyUnit {
        case .days:
            return amount * Double(365 / max(frequencyValue, 1))
        case .weeks:
            return amount * Double(52 / max(frequencyValue, 1))
        case .months:
            return amount * Double(12 / max(frequencyValue, 1))
        case .years:
            return amount * Double(1 / max(frequencyValue, 1))
        }
    }
}
