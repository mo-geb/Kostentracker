//
//  ExpenseDetailView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData
import PhotosUI

struct ExpenseDetailView: View {
    // MARK: - Properties
    
    // SwiftData
    @Query(sort: \ExpenseCategory.sortOrder) var categories: [ExpenseCategory]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // State
    @State private var initialState: ActiveExpenseSheet
    @State private var expense: Expense?
    @State private var draft: ExpenseDraft
    @State private var isEditing: Bool
    @State private var showingDeleteAlert = false
    @State private var selectedPhoto: PhotosPickerItem?
    
    // User Settings
    @AppStorage(AppSettings.currencyKey) private var currencyCode: String = "EUR"

    // Focus management
    @FocusState private var focusedField: FocusedField?

    // Construct
    init(initialState: ActiveExpenseSheet) {
        self.initialState = initialState
        switch initialState {
        case .view(let e):
            self.expense = e
            self._draft = State(initialValue: ExpenseDraft(from: e))
            self._isEditing = State(initialValue: false)
        case .edit(let e):
            self.expense = e
            self._draft = State(initialValue: ExpenseDraft(from: e))
            self._isEditing = State(initialValue: true)
        case .new(let d):
            self.expense = nil
            self._draft = State(initialValue: d)
            self._isEditing = State(initialValue: true)
        }
    }
    
    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                pictureSection
                titleSection
                
                detailsSection
                
                if isEditing && expense != nil {
                    deleteButton
                } else if !isEditing {
                    statisticsSection
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            toolbarContent
        }
        .onTapGesture {
            focusedField = nil
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
                            draft.customImageData = data
                        }
                    }
                }

                if draft.customImageData != nil {
                    Button() {
                        draft.customImageData = nil
                    } label: {
                        Label("Remove", systemImage: "eraser")
                    }
                    .padding(.top, 8)
                }
            } else {
                imageDisplay
            }
        }
        .padding(.bottom)
    }
    
    /// A reusable view that displays the expense's custom image or a placeholder as an app-shaped icon.
    @ViewBuilder
    private var imageDisplay: some View {
        ZStack {
            if let imageData = (isEditing ? draft.customImageData : expense?.customImageData), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                ZStack {
                    Circle()
                        .fill((isEditing ? (draft.category?.color ?? .gray) : (expense?.categoryColor ?? .gray)).opacity(0.3))
                    
                    Image(systemName: isEditing ? (draft.category?.iconName ?? "tag") : (expense?.categoryIconName ?? "tag"))
                        .font(.system(size: 40))
                        .foregroundStyle(isEditing ? (draft.category?.color ?? .gray) : (expense?.categoryColor ?? .gray))
                }
            }
        }
        .frame(width: 100, height: 100)
        .offset(y: -10)
        .padding(-15)
    }
    
    @ViewBuilder
    private var titleSection: some View {
        if isEditing {
            TextField("Title", text: $draft.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(-10)
                .focused($focusedField, equals: .expenseDetailTitle)
                .onChange(of: draft.title) { _, newValue in
                    if newValue.count > 20 {
                        draft.title = String(newValue.prefix(20))
                    }
                }
        } else {
            Text(expense?.title ?? "")
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
            row(title: String(localized: "Amount")) {
                if isEditing {
                    TextField("0.00", value: $draft.amount, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .fixedSize()
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .focused($focusedField, equals: .expenseDetailAmount)
                        .onChange(of: draft.amount) { _, newValue in
                            if newValue < 0 {
                                draft.amount = 0
                            }
                        }
                        .onAppear {
                            if draft.amount == 0 {
                                // This ensures the placeholder shows when the field is empty
                            }
                        }
                } else {
                    if let amount = expense?.amount, amount == 0 {
                        Text("0.00")
                            .foregroundStyle(.secondary)
                    } else if let amount = expense?.amount {
                        Text(amount, format: .currency(code: currencyCode))
                    }
                }
            }
            
            row(title: String(localized: "Frequency")) {
                if isEditing {
                    HStack {
                        Text("Every")
                            .foregroundStyle(.secondary)
                        Picker("Frequency Value", selection: $draft.frequencyValue) {
                            ForEach(draft.frequencyUnit.valueRange, id: \.self) { value in
                                Text("\(value)").tag(Int16(value))
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .onChange(of: draft.frequencyUnit) { _, newUnit in
                            let maxValue = newUnit.valueRange.upperBound
                            if draft.frequencyValue > maxValue {
                                draft.frequencyValue = maxValue
                            }
                        }
                        Picker("Unit", selection: $draft.frequencyUnit) {
                            ForEach(FrequencyUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName(for: draft.frequencyValue))
                                    .tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    if let freqValue = expense?.frequencyValue, let freqUnit = expense?.frequencyUnit {
                        Text(FrequencyUnit.formatFrequency(value: freqValue, unit: freqUnit))
                    }
                }
            }
            
            row(title: String(localized: "Date")) {
                if isEditing {
                    DatePicker("", selection: $draft.date, displayedComponents: [.date])
                        .labelsHidden()
                } else {
                    if let date = expense?.date {
                        Text(date, style: .date)
                    }
                }
            }
            
            row(title: String(localized: "Category")) {
                if isEditing {
                    Picker("Category", selection: $draft.category) {
                        ForEach(categories, id: \.self) { category in
                            HStack(spacing: 8) {
                                Image(systemName: category.iconName)
                                    .foregroundStyle(category.color)
                                    .frame(width: 16)
                                Text(category.name)
                            }
                            .tag(Optional(category))
                        }
                    }
                    .pickerStyle(.menu)
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    if let name = expense?.categoryName, let icon = expense?.categoryIconName {
                        Label(name, systemImage: icon)
                    }
                }
            }
            
            // Notes section
            VStack(alignment: .leading) {
                Text("Notes").font(.headline)
                if isEditing {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $draft.notes)
                            .padding(12)
                            .frame(minHeight: 100)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .scrollContentBackground(.hidden)
                            .focused($focusedField, equals: .expenseDetailNotes)
                    }
                } else {
                    VStack {
                        if let notes = expense?.notes, !notes.isEmpty {
                            Text(notes)
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

                let yearlyCost = expense?.yearlyCost ?? 0
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
                .minimumScaleFactor(0.7)
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
            HStack {
                Image(systemName: "trash")
                Text("Delete")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .padding(.vertical, 14)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.15))
            )
        }
        .frame(maxWidth: 260)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal)
        .alert("Delete Expense?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let expense = expense {
                    context.delete(expense)
                }
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
                    if draft.title.isEmpty && draft.amount == 0 {
                        switch initialState {
                        case .edit(let expense), .view(let expense):
                            context.delete(expense)
                        case .new:
                            break
                        }
                    }
                    dismiss()
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
                        switch initialState {
                        case .edit(let expense), .view(let expense):
                            expense.update(from: draft)
                        case .new:
                            let newExpense = Expense(from: draft)
                            context.insert(newExpense)
                            try context.save()
                            self.expense = newExpense
                            self.isEditing = false
                        }
                        try context.save()
                        isEditing = false
                    } catch {
                        print("Failed to save expense: \(error)")
                    }
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .disabled(draft.title.isEmpty)
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
}
