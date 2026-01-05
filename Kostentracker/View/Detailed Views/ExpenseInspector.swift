import SwiftUI
import SwiftData
import PhotosUI

struct ExpenseInspector: View {
    // MARK: - Properties
    // Shared
    @EnvironmentObject var ui: UIState
    
    // SwiftData
    @Query(sort: \ExpenseCategory.sortOrder) var categories: [ExpenseCategory]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // State
    @State private var initialState: ActiveExpenseSheet
    @State private var expense: Expense?
    @State private var draft: ExpenseDraft
    @State private var isEditing: Bool
    @State private var amountText: String = ""
    @State private var showingDeleteAlert = false
    @State private var selectedPhoto: PhotosPickerItem?
    
    // User Settings
    @EnvironmentObject var userSettings: UserSettings
    
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
                    .accessibilitySortPriority(1)
                titleSection
                    .accessibilitySortPriority(2)
                
                detailsSection
                    .accessibilitySortPriority(3)
                
                if isEditing && expense != nil {
                    deleteButton
                        .accessibilitySortPriority(4)
                } else if !isEditing {
                    markAsPaidButton
                        .accessibilitySortPriority(4)
                    statisticsSection
                        .accessibilitySortPriority(5)
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
        .overlay {
            if ui.activePopup == ActivePopup.markedAsPaid(owner: ActivePopup.MarkedAsPaidOwner.inspector) {
                MarkAsPaidPopup()
            }
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
                                .accessibilityHidden(true)
                        }
                }
                .accessibilityLabel(draft.customImageData != nil ? "Change expense image" : "Add expense image")
                .accessibilityHint("Double tap to select a photo from your library")
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
                    .frame(minWidth: 44, minHeight: 44)
                    .padding(.top, 8)
                    .accessibilityLabel("Remove expense image")
                    .accessibilityHint("Double tap to remove the current image")
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
                    .accessibilityLabel("Custom expense image")
            } else {
                ZStack {
                    Circle()
                        .fill((isEditing ? (draft.category?.color ?? .gray) : (expense?.categoryColor ?? .gray)).opacity(0.3))
                    
                    Image(systemName: isEditing ? (draft.category?.iconName ?? "tag") : (expense?.categoryIconName ?? "tag"))
                        .font(.system(size: 40))
                        .foregroundStyle(isEditing ? (draft.category?.color ?? .gray) : (expense?.categoryColor ?? .gray))
                }
                .accessibilityLabel("Category icon: \(isEditing ? (draft.category?.iconName ?? "tag") : (expense?.categoryIconName ?? "tag"))")
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
                .lineLimit(2)
                .padding(.horizontal)
                .padding(-10)
                .focused($focusedField, equals: .expenseDetailTitle)
                .accessibilityLabel("Expense title")
                .accessibilityHint("Enter a title for this expense. Maximum 20 characters.")
                .accessibilityValue(draft.title.isEmpty ? "Empty" : draft.title)
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
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal)
                .padding(-10)
                .accessibilityLabel("Expense title: \(expense?.title ?? "No title")")
        }
    }
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Amount Section
            row(title: String(localized: "Amount"), icon: "number") {
                if isEditing {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .fixedSize()
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .focused($focusedField, equals: .expenseDetailAmount)
                        .accessibilityLabel("Expense amount")
                        .accessibilityHint("Enter the cost amount using decimal format")
                        .accessibilityValue(amountText.isEmpty ? "No amount entered" : "\(amountText) \(userSettings.currencyCode)")
                        .onChange(of: amountText) { _, newValue in
                            let formatter = NumberFormatter()
                            formatter.locale = Locale.current
                            formatter.numberStyle = .decimal
                            
                            if let number = formatter.number(from: newValue) {
                                draft.amount = max(0, number.doubleValue)
                            } else {
                                draft.amount = 0
                            }
                        }
                        .onChange(of: focusedField) { _, focused in
                            if focusedField != .expenseDetailAmount {
                                let formatter = NumberFormatter()
                                formatter.locale = Locale.current
                                formatter.numberStyle = .decimal
                                formatter.minimumFractionDigits = 2
                                formatter.maximumFractionDigits = 2
                                
                                if draft.amount > 0 {
                                    amountText = formatter.string(from: NSNumber(value: draft.amount)) ?? ""
                                } else {
                                    amountText = ""
                                }
                            }
                        }
                        .onAppear {
                            let formatter = NumberFormatter()
                            formatter.locale = Locale.current
                            formatter.numberStyle = .decimal
                            formatter.minimumFractionDigits = 2
                            formatter.maximumFractionDigits = 2
                            
                            amountText = draft.amount > 0 ? (formatter.string(from: NSNumber(value: draft.amount)) ?? "") : ""
                        }
                } else {
                    if let amount = expense?.amount, amount == 0 {
                        Text("0.00")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Amount: No amount set")
                    } else if let amount = expense?.amount {
                        Text(amount, format: .currency(code: userSettings.currencyCode))
                            .accessibilityLabel("Amount: \(amount, format: .currency(code: userSettings.currencyCode))")
                    }
                }
            }
            
            // Due / Frequency Section
            rowGroup {
                if isEditing {
                    innerRow(title: String(localized: "Next Due"), icon: "calendar") {
                        DatePicker("", selection: $draft.date, displayedComponents: [.date])
                            .labelsHidden()
                            .accessibilityLabel("Expense date")
                            .accessibilityHint("Select the date for this expense")
                            .accessibilityValue(draft.date.formatted(date: .abbreviated, time: .omitted))
                    }
                    
                    customDivider
                    
                    innerRow(title: String(localized: "Repeat"), icon: "arrow.trianglehead.counterclockwise") {
                        Toggle("", isOn: Binding(
                            get: { draft.frequencyValue != 0 },
                            set: { newValue in
                                draft.frequencyValue = newValue ? 1 : 0
                            }))
                    }
                    
                    if draft.type == .recurring {
                        customDivider
                        
                        innerRow(title: String(localized: "Frequency"), icon: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
                            HStack {
                                Picker("Frequency Value", selection: $draft.frequencyValue) {
                                    ForEach(draft.frequencyUnit.valueRange, id: \.self) { value in
                                        Text("\(value)").tag(Int16(value))
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 80)
                                .accessibilityLabel("Frequency Value")
                                .accessibilityHint("Select how often this expense occurs")
                                .accessibilityValue("\(draft.frequencyValue)")
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
                                .fixedSize(horizontal: true, vertical: false)
                                .accessibilityLabel("Frequency unit")
                                .accessibilityHint("Select the time unit for frequency")
                                .accessibilityValue(draft.frequencyUnit.displayName(for: draft.frequencyValue))
                                .layoutPriority(1)
                                
                            }
                        }
                    }
                } else {
                    innerRow(title: String(localized: "Next Due"), icon: "calendar.badge.exclamationmark") {
                        if let date = expense?.date {
                            Text(date, style: .date)
                                .accessibilityLabel("Date: \(date.formatted(date: .abbreviated, time: .omitted))")
                        }
                    }
                    if expense?.type == .recurring {
                        customDivider
                        
                        innerRow(title: String(localized: "Repeat"), icon: "arrow.trianglehead.counterclockwise") {
                            if let freqValue = expense?.frequencyValue, let freqUnit = expense?.frequencyUnit {
                                Text(freqUnit.displayText(for: freqValue))
                                    .accessibilityLabel("Frequency: \(freqUnit.displayText(for: freqValue))")
                            }
                        }
                    }
                }
            }
            
            // Category section
            row(title: String(localized: "Category"), icon: "archivebox") {
                if isEditing {
                    Picker("Category", selection: $draft.category) {
                        ForEach(categories, id: \.self) { category in
                            HStack(spacing: 8) {
                                Image(systemName: category.iconName)
                                    .foregroundStyle(category.color)
                                    .frame(width: 16)
                                    .accessibilityLabel("\(category.iconName) icon")
                                Text(category.name)
                            }
                            .tag(Optional(category))
                        }
                    }
                    .pickerStyle(.menu)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Expense category")
                    .accessibilityHint("Select a category for this expense")
                    .accessibilityValue(draft.category?.name ?? "No category selected")
                } else {
                    if let name = expense?.categoryName, let icon = expense?.categoryIconName {
                        Label(name, systemImage: icon)
                            .accessibilityLabel("Category: \(name)")
                    }
                }
            }
            
            // Notes section
            VStack(alignment: .leading) {
                Text("Notes")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                if isEditing {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $draft.notes)
                            .padding(12)
                            .frame(minHeight: 100)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .scrollContentBackground(.hidden)
                            .focused($focusedField, equals: .expenseDetailNotes)
                            .accessibilityLabel("Expense notes")
                            .accessibilityHint("Add optional notes or details about this expense")
                            .accessibilityValue(draft.notes.isEmpty ? "No notes" : draft.notes)
                    }
                } else {
                    VStack {
                        if let notes = expense?.notes, !notes.isEmpty {
                            Text(notes)
                                .accessibilityLabel("Notes: \(notes)")
                        } else {
                            Text("No notes provided.")
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Notes: No notes provided")
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
    private var markAsPaidButton: some View {
        Button() {
            if let e = expense {
                switch e.type {
                case .oneTime:
                    context.delete(e)
                    dismiss()
                case .recurring:
                    e.advanceDueDate()
                    ui.showMarkedAsPaidConfirmation(owner: ActivePopup.MarkedAsPaidOwner.inspector)
                }
                try? context.save()
            }
        } label: {
            HStack {
                Image(systemName: "checkmark")
                Text("Mark as paid")
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 32)
            .foregroundColor(.green)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.green.opacity(0.15))
            )
        }
        .frame(maxWidth: 260)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .accessibilityLabel("Mark expense as paid")
        .accessibilityHint("Mark this expense as paid and update its status")
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        VStack {
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Statistics")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                
                HStack {
                    costCard(title: "Yearly", amount: expense?.yearlyCost ?? 0)
                    costCard(title: "Monthly", amount: expense?.monthlyCost ?? 0)
                    costCard(title: "Weekly", amount: expense?.weeklyCost ?? 0)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Cost breakdown")
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
            Text(amount, format: .currency(code: userSettings.currencyCode))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) cost: \(amount, format: .currency(code: userSettings.currencyCode))")
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
        .accessibilityLabel("Delete expense")
        .accessibilityHint("Permanently delete this expense. This action cannot be undone.")
        .alert("Delete Expense?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let expense = expense {
                    context.delete(expense)
                }
                dismiss()
            }
            .accessibilityLabel("Confirm delete")
            Button("Cancel", role: .cancel) { }
                .accessibilityLabel("Cancel delete")
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
                    do {
                        switch initialState {
                        case .edit(_), .view(_):
                            isEditing = false
                        case .new:
                            dismiss()
                        }
                    }
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
                .accessibilityLabel("Cancel editing")
                .accessibilityHint("Discard changes and return to view mode")
            } else {
                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "chevron.down")
                }
                .accessibilityLabel("Close expense details")
                .accessibilityHint("Return to the previous screen")
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
                .accessibilityLabel("Save expense")
                .accessibilityHint(draft.title.isEmpty ? "Title is required to save" : "Save changes to this expense")
            } else {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .accessibilityLabel("Edit expense")
                .accessibilityHint("Switch to edit mode to modify this expense")
            }
        }
    }
    
    // MARK: - Helper Views
    
    /// A generic row builder to reduce duplication of HStack, Spacer, etc.
    @ViewBuilder
    private func row<Content: View>(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(width: 20)
            }
            Text(title)
            Spacer()
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func innerRow<Content: View>(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(width: 20)
            }
            Text(title)
            Spacer()
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func rowGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var customDivider: some View {
        Divider()
            .padding(.leading, 44)
            .padding(.trailing, 20)
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: Expense.self, ExpenseCategory.self)
        let context = container.mainContext
        
        #if DEBUG
        print("Entered App in DEBUG... Deleting models")
        try? context.delete(model: Expense.self)
        try? context.delete(model: ExpenseCategory.self)

        UserDefaults.standard.removeObject(forKey: "hasCreatedDefaultCategories")
        #endif
        
        UserDefaults.standard.removeObject(forKey: "hasCreatedDefaultCategories")
        
        SampleData.categories.forEach {
            container.mainContext.insert($0)
        }
        
        SampleData.expenses.forEach {
            container.mainContext.insert($0)
        }
        
        return NavigationStack {
            ExpenseInspector(initialState: .edit(SampleData.netflixSample))
                .modelContainer(container)
                .environmentObject(UIState())
                .environmentObject(UserSettings())
        }
        
    } catch {
        return Text("Failed to create preview container: \(error.localizedDescription)")
    }
}
