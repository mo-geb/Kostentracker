import SwiftUI
import SwiftData
import PhotosUI

struct ExpenseInspector: View {
    // MARK: - Properties
    // Shared
    @Environment(UIState.self) private var ui: UIState

    // SwiftData
    @Query(sort: \ExpenseCategory.sortOrder) var categories: [ExpenseCategory]
    @Query(sort: \ExpenseAccount.sortOrder) var accounts: [ExpenseAccount]
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
    @State private var emojiInput: String = ""
    
    @State private var showFrequencyPicker: Bool = false
    @State private var showPhotoPicker = false
    
    // User Settings
    @Environment(UserSettings.self) var userSettings
    
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
        @Bindable var ui = ui
        ScrollView {
            VStack(spacing: 20) {
                pictureSection
                    .accessibilitySortPriority(1)
                titleSection
                    .accessibilitySortPriority(2)
                detailsSection
                    .accessibilitySortPriority(3)
                
                if isEditing {
                    if expense != nil {
                        deleteButton
                            .accessibilitySortPriority(4)
                    }
                } else {
                    if draft.type == .inactive {
                        inactiveInfo
                            .accessibilitySortPriority(4)
                    } else {
                        markAsPaidButton
                            .accessibilitySortPriority(4)
                        statisticsSection
                            .accessibilitySortPriority(5)
                    }
                }
            }
        }
        .background {
            hiddenEmojiTextField
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            toolbarContent
        }
        .onTapGesture {
            focusedField = nil
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
        .sheet(item: $ui.activeCategorySheet) { sheet in
            switch sheet {
            case .new(let draft):
                NavigationStack {
                    CategoryInspector(initialState: .new(draft))
                }
            default: EmptyView()
            }
        }
        .sheet(item: $ui.activeAccountSheet) { sheet in
            switch sheet {
            case .new(let draft):
                NavigationStack {
                    AccountInspector(initialState: .new(draft))
                }
            default: EmptyView()
            }
        }
        .overlay {
            if ui.activePopup == ActivePopup.markedAsPaid(owner: ActivePopup.PopupOwner.inspector) {
                MarkAsPaidPopup()
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var pictureSection: some View {
        VStack {
            if isEditing {
                imageDisplay
                    .overlay(alignment: .bottomTrailing) {
                        Menu {
                            // Option 1: Photo Library
                            Button {
                                showPhotoPicker = true
                            } label: {
                                Label("Choose Photo", systemImage: "photo.on.rectangle")
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
                            
                            // Option 2: Emoji Keyboard
                            Button {
                                focusedField = .expenseEmojiKeyboard
                            } label: {
                                Label("Choose Emoji", systemImage: "face.smiling")
                            }
                            
                            // Option 3: Remove (Only if media exists)
                            if draft.customImageData != nil {
                                Button(role: .destructive) {
                                    draft.customImageData = nil
                                } label: {
                                    Label("Remove Current", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.title)
                        }
                        .offset(x: 8, y: 8)
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
        let media = isEditing ? draft.displayMedia : (expense?.displayMedia ?? .icon("tag", .gray))
        
        ZStack {
            switch media {
            case .image(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .accessibilityLabel("Custom expense image")
            case .emoji(let emoji, let color):
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                    Text(emoji)
                        .font(.system(size: 70))
                }
                .accessibilityLabel("Expense emoji: \(emoji)")
            case .icon(let name, let color):
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                    Image(systemName: name)
                        .font(.system(size: 40))
                        .foregroundStyle(color)
                }
                .accessibilityLabel("Category icon: \(name)")
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
            amountSection
            dateSection
            categorySection
            notesSection
        }
        .padding()
    }
    
    @ViewBuilder
    private var amountSection: some View {
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
    }
    
    @ViewBuilder
    private var dateSection: some View {
        if isEditing {
            // Active / Date
            rowGroup {
                row(title: String(localized: "Active"), icon: "lightbulb") {
                    Toggle("", isOn: Binding(
                        get: { draft.date != Date.distantPast },
                        set: { newValue in
                            draft.date = newValue ? Date.now : Date.distantPast
                        }))
                }
                
                if draft.type != .inactive {
                    customDivider
                    
                    row(title: String(localized: "Next Due"), icon: "calendar") {
                        DatePicker("", selection: $draft.date, displayedComponents: [.date])
                            .labelsHidden()
                            .accessibilityLabel("Expense date")
                            .accessibilityHint("Select the date for this expense")
                            .accessibilityValue(draft.date.formatted(date: .abbreviated, time: .omitted))
                            .focused($focusedField, equals: .expenseDueDate)
                    }
                }
            }
            
            // Repeat / Frequency
            if draft.type != .inactive {
                rowGroup {
                    row(title: String(localized: "Repeat"), icon: "arrow.trianglehead.counterclockwise") {
                        Toggle("", isOn: Binding(
                            get: { draft.frequencyValue != 0 },
                            set: { newValue in
                                draft.frequencyValue = newValue ? 1 : 0
                            }))
                    }
                    
                    if draft.type == .recurring {
                        customDivider
                        
                        row(title: String(localized: "Frequency"), icon: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
                            Button {
                                showFrequencyPicker = true
                            } label: {
                                Text(draft.frequencyUnit.displayText(for: draft.frequencyValue))
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .accessibilityLabel("Frequency: \(draft.frequencyUnit.displayText(for: draft.frequencyValue))")
                            }
                            .sheet(isPresented: $showFrequencyPicker) {
                                VStack(spacing: 0) {
                                    HStack {
                                        Spacer()
                                        Button("Done") {
                                            showFrequencyPicker = false
                                        }
                                        .fontWeight(.bold)
                                    }
                                    .padding()
                                    
                                    HStack(spacing: 0) {
                                        Picker("Value", selection: $draft.frequencyValue) {
                                            ForEach(draft.frequencyUnit.valueRange, id: \.self) { value in
                                                Text("\(value)").tag(Int16(value))
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        
                                        Picker("Unit", selection: $draft.frequencyUnit) {
                                            ForEach(FrequencyUnit.allCases, id: \.self) { unit in
                                                Text(unit.displayName(for: draft.frequencyValue))
                                                    .tag(unit)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                    }
                                }
                                .presentationDetents([.height(300)])
                                .presentationDragIndicator(.hidden)
                            }
                        }
                    }
                }
            }
        } else {
            if draft.type != .inactive {
                rowGroup {
                    // Due
                    row(title: String(localized: "Next Due"), icon: "calendar.badge.exclamationmark") {
                        if let date = expense?.date {
                            Text(date, style: .date)
                                .accessibilityLabel("Date: \(date.formatted(date: .abbreviated, time: .omitted))")
                        }
                    }
                    
                    // Repeat Frequency
                    if draft.type == .recurring {
                        customDivider
                        
                        row(title: String(localized: "Repeat"), icon: "arrow.trianglehead.counterclockwise") {
                            if let freqValue = expense?.frequencyValue, let freqUnit = expense?.frequencyUnit {
                                Text(freqUnit.displayText(for: freqValue))
                                    .accessibilityLabel("Frequency: \(freqUnit.displayText(for: freqValue))")
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var categorySection: some View {
        rowGroup {
            // Category
            row(title: String(localized: "Category"), icon: "archivebox") {
                if isEditing {
                    Menu {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                draft.category = category
                            } label: {
                                Label(category.name, systemImage: category.iconName)
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            let draft = CategoryDraft.createNew(
                                sortOrder: (categories.last?.sortOrder ?? 0) + 1
                            )
                            ui.createCategory(from: draft)
                        } label: {
                            Label("New Category", systemImage: "plus")
                        }
                    } label: {
                        if let category = draft.category {
                            Label(category.name, systemImage: category.iconName)
                        }
                        
                    }
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
            
            // Account
            if userSettings.enableAccounts {
                row(title: String(localized: "Account"), icon: "person.2") {
                    if isEditing {
                        Menu {
                            ForEach(accounts, id: \.self) { account in
                                Button {
                                    draft.account = account
                                } label: {
                                    Label(account.name, systemImage: account.iconName)
                                }
                            }
                            
                            Divider()
                            
                            Button {
                                let draft = AccountDraft.createNew(
                                    sortOrder: (accounts.last?.sortOrder ?? 0) + 1
                                )
                                ui.createAccount(from: draft)
                            } label: {
                                Label("New Account", systemImage: "plus")
                            }
                        } label: {
                            if let account = draft.account {
                                Label(account.name, systemImage: account.iconName)
                            }
                            
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Expense account")
                        .accessibilityHint("Select an account for this expense")
                        .accessibilityValue(draft.account?.name ?? "No account selected")
                    } else {
                        if let name = expense?.account?.name, let icon = expense?.account?.iconName {
                            Label(name, systemImage: icon)
                                .accessibilityLabel("Account: \(name)")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var notesSection: some View {
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
    
    private var hiddenEmojiTextField: some View {
        TextField("", text: $emojiInput)
            .keyboardType(UIKeyboardType(rawValue: 124) ?? .default)
            .focused($focusedField, equals: .expenseEmojiKeyboard)
            .opacity(0)
            .frame(width: 0, height: 0)
            .onChange(of: emojiInput) { _, newValue in
                guard !newValue.isEmpty else { return }
                
                if let lastChar = newValue.last, lastChar.isEmoji {
                    draft.customImageData = String(lastChar).data(using: .utf8)
                    
                    focusedField = .none
                    UISelectionFeedbackGenerator().selectionChanged()
                }
                
                emojiInput = ""
            }
    }
    
    @ViewBuilder
    private var inactiveInfo: some View {
        ContentUnavailableView(
            "Expense Inactive",
            systemImage: "info.circle.fill",
            description: Text("Edit Expense and add a date to make active again"))
        .frame(maxWidth: 260)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .accessibilityLabel("Mark expense as paid")
        .accessibilityHint("Mark this expense as paid and update its status")
    }
    
    @ViewBuilder
    private var markAsPaidButton: some View {
        Button() {
            if let e = expense {
                switch e.type {
                case .oneTime, .inactive:
                    context.delete(e)
                    dismiss()
                    ui.showDeletedPopup(owner: ActivePopup.PopupOwner.main)
                case .recurring:
                    e.advanceDueDate()
                    ui.showMarkedAsPaidConfirmation(owner: ActivePopup.PopupOwner.inspector)
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
                ui.showDeletedPopup(owner: ActivePopup.PopupOwner.main)
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
                            self.initialState = .view(newExpense)
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
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

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        ExpenseInspector(initialState: .edit(SampleData.oneTime))
            .environment(UIState())
            .environment(UserSettings())
    }
}
