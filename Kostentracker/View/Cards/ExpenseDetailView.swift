//
//  ExpenseDetailView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData
import PhotosUI

struct ExpenseDetailView: View {
    // MARK: - Properties
    
    @Bindable var expense: Expense
    @Query(sort: \ExpenseCategory.name) var categories: [ExpenseCategory]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing: Bool
    @State private var showingDeleteAlert = false
    @State private var selectedPhoto: PhotosPickerItem?
    var onSave: (() -> Void)?
    
    @AppStorage(AppSettings.currencyKey) private var currencyCode: String = "EUR"
    
    init(expense: Expense, isEditingInitial: Bool = false, onSave: (() -> Void)? = nil) {
        self._expense = Bindable(wrappedValue: expense)
        self._isEditing = State(initialValue: isEditingInitial)
        self.onSave = onSave
    }
    
    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                pictureSection
                titleSection
                
                detailsSection
                
                if isEditing {
                    deleteButton
                } else {
                    statisticsSection
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            toolbarContent
        }
    }

    // MARK: - View Components
    
    @ViewBuilder
    private var pictureSection: some View {
        VStack {
            if isEditing {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    imageDisplay
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title)
                                .offset(x: 10, y: 10)
                        }
                }
                .onChange(of: selectedPhoto) {
                    Task {
                        if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                            expense.customImageData = data
                        }
                    }
                }
            } else {
                imageDisplay
            }
        }
        .padding(.bottom)
    }
    
    /// A reusable view that displays the expense's custom image or a placeholder as a circular icon.
    @ViewBuilder
    private var imageDisplay: some View {
        ZStack {
            Circle()
                .fill(Color(.tertiarySystemBackground))

            if let imageData = expense.customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                // Show category icon with circular background when no custom image
                ZStack {
                    Circle()
                        .fill(expense.category.color.opacity(0.3))
                    
                    Image(systemName: expense.category.iconName)
                        .font(.system(size: 40))
                        .foregroundStyle(expense.category.color)
                }
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .offset(y: -10)
        .padding(-15)
    }
    
    @ViewBuilder
    private var titleSection: some View {
        if isEditing {
            TextField("Title", text: $expense.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(-10)
        } else {
            Text(expense.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(-10)
        }
    }
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            row(title: "Amount") {
                if isEditing {
                    TextField("0.00", value: Binding(
                        get: { expense.amount },
                        set: { expense.amount = max(0, $0) }
                    ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .fixedSize()
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                } else {
                    Text(expense.amount, format: .currency(code: currencyCode))
                }
            }
            
            row(title: "Frequency") {
                if isEditing {
                    HStack {
                        Text("Every")
                            .foregroundStyle(.secondary)
                        
                        TextField("1", value: Binding(
                            get: { Int(expense.frequencyValue) },
                            set: { expense.frequencyValue = Int16(max(1, $0)) }
                        ), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .fixedSize()
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        
                        Picker("Unit", selection: $expense.frequencyUnit) {
                            ForEach(FrequencyUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName(for: expense.frequencyValue))
                                    .tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(FrequencyUnit.formatFrequency(value: expense.frequencyValue, unit: expense.frequencyUnit))
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
                    Picker("Category", selection: $expense.category) {
                        ForEach(categories, id: \.self) { category in
                            HStack(spacing: 8) {
                                Image(systemName: category.iconName)
                                    .foregroundStyle(category.color)
                                    .frame(width: 16)
                                Text(category.name)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    Label(expense.category.name, systemImage: expense.category.iconName)
                }
            }
            
            // Notes section
            VStack(alignment: .leading) {
                Text("Notes").font(.headline)
                if isEditing {
                    TextEditor(text: $expense.notes)
                        .padding(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.tertiarySystemBackground), lineWidth: 1)
                        )
                        .frame(minHeight: 100)
                        .cornerRadius(16)
                } else {
                    VStack {
                        if !expense.notes.isEmpty {
                            Text(expense.notes)
                        } else {
                            Text("No notes provided.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
                
                HStack {
                    costCard(title: "Yearly", amount: yearlyCost)
                    costCard(title: "Monthly", amount: monthlyCost)
                    costCard(title: "Weekly", amount: weeklyCost)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
    
    /// A reusable view for displaying a single cost metric (e.g., "Yearly").
    private func costCard(title: String, amount: Double) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text(amount, format: .currency(code: currencyCode))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(.red)
        .alert("Delete Expense?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(expense)
                dismiss()
            }
                    
            Button("Cancel", role: .cancel) { }
                    
        } message: {
            Text("Are you sure? This action cannot be undone.")
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if isEditing {
                Button {
                    // If this is a new expense that hasn't been saved yet, delete it
                    if expense.title.isEmpty && expense.amount == 0 {
                        context.delete(expense)
                    } else {
                        // Reload from persistent store if cancel pressed
                        context.rollback()
                    }
                    isEditing = false
                    dismiss()
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
                .disabled(expense.title.isEmpty)
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
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(25)
    }

    // MARK: - Logic
    
    private func calculateYearlyCost(amount: Double, frequencyValue: Int, frequencyUnit: FrequencyUnit) -> Double {
        guard frequencyValue > 0 else { return 0 }
        switch frequencyUnit {
        case .day:
            return amount * (365.0 / Double(frequencyValue))
        case .week:
            return amount * (52.0 / Double(frequencyValue))
        case .month:
            return amount * (12.0 / Double(frequencyValue))
        case .year:
            return amount / Double(frequencyValue)
        }
    }
    

}
