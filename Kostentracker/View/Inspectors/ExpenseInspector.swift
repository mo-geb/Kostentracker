import SwiftUI
import SwiftData
import PhotosUI

struct ExpenseInspector: View {
    // MARK: - Properties

    @Environment(UIState.self) private var uiState: UIState
    @Environment(UserSettings.self) var userSettings
    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \ExpenseCategory.sortOrder) var categories: [ExpenseCategory]
    @Query(sort: \ExpenseAccount.sortOrder) var accounts: [ExpenseAccount]

    @State private var initialState: ActiveExpenseSheet
    @State private var expense: Expense?
    @State private var draft: ExpenseDraft
    @State private var isEditing: Bool
    @State private var amountText: String = ""
    @State private var showingDeleteAlert = false
    @State private var successHaptic = 0
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var emojiInput: String = ""
    @State private var showFrequencyPicker = false
    @State private var showPhotoPicker = false
    @State private var showPaywall = false

    @FocusState private var focusedField: FocusedField?

    private static let amountParseFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        return f
    }()

    private static let amountDisplayFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()
    
    /// True when presented modally (the "new expense" sheet). Pushed view/edit
    /// presentations leave this false so the system back button handles dismissal
    /// instead of a redundant Close button.
    private let isPresentedAsSheet: Bool

    // Construct
    init(initialState: ActiveExpenseSheet, isPresentedAsSheet: Bool = false) {
        self.initialState = initialState
        self.isPresentedAsSheet = isPresentedAsSheet
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
        @Bindable var ui = uiState
        Form {
            Section {
                VStack(spacing: 8) {
                    if isEditing { pictureSectionEditing } else { pictureSectionShowing }
                    if isEditing { titleSectionEditing } else { titleSectionShowing }
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if isEditing {
                Section { amountRowEditing }

                Section {
                    activeRowEditing
                    if draft.type != .inactive { dueRowEditing }
                }

                if draft.type != .inactive {
                    Section {
                        repeatRowEditing
                        if draft.type == .recurring { frequencyRowEditing }
                    }
                }

                Section {
                    categoryRowEditing
                    if store.accountsAvailable(in: userSettings) { accountRowEditing }
                }

                notesSectionEditing

                if case .new(_) = initialState { } else {
                    Section {
                        deleteButton
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())
                }
            } else {
                Section { amountRowShowing }

                if draft.type != .inactive {
                    Section {
                        dueRowShowing
                        if draft.type == .recurring { repeatRowShowing }
                    }
                }

                Section {
                    categoryRowShowing
                    if store.accountsAvailable(in: userSettings) { accountRowShowing }
                }

                notesSectionShowing

                if draft.type == .inactive {
                    Section {
                        inactiveInfo
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())
                } else {
                    Section {
                        markAsPaidButton
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())

                    statisticsSection
                }
            }
        }
        .listSectionSpacing(20)
        .contentMargins(.top, 4, for: .scrollContent)
        .background { hiddenEmojiTextField }
        .scrollDismissesKeyboard(.interactively)
        .toolbar { toolbarContent }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .fontWeight(.semibold)
            }
        }
        .paywallSheet(isPresented: $showPaywall)
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
        .onAppear {
            if case .new(_) = initialState {
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    focusedField = .expenseDetailTitle
                }
            }
        }
        .sensoryFeedback(.success, trigger: successHaptic)
        .sensoryFeedback(.selection, trigger: draft.customImageData)
    }
    
    // MARK: - View Components
    
    // MARK: Picture Section
    @ViewBuilder
    private var pictureSectionEditing: some View {
        pictureSectionShowing
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
                .offset(x: 10, y: 10)
            }
    }
    
    @ViewBuilder
    private var pictureSectionShowing: some View {
        ZStack {
            switch draft.displayMedia {
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
                        .font(.system(size: 50))
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
    }
    
    // MARK: Title Section
    
    @ViewBuilder
    private var titleSectionEditing: some View {
        TextField("Title", text: $draft.title)
            .font(.title)
            .bold()
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .focused($focusedField, equals: .expenseDetailTitle)
            .accessibilityLabel("Expense title")
            .accessibilityHint("Enter a title for this expense. Maximum 20 characters.")
            .accessibilityValue(draft.title.isEmpty ? "Empty" : draft.title)
            .onChange(of: draft.title) { _, newValue in
                if newValue.count > 20 {
                    draft.title = String(newValue.prefix(20))
                }
            }
    }
    
    @ViewBuilder
    private var titleSectionShowing: some View {
        Text(draft.title)
            .font(.title)
            .bold()
            .multilineTextAlignment(.center)
            .accessibilityLabel("Expense title: \(expense?.title ?? "No title")")
    }
    
    // MARK: Amount
    
    @ViewBuilder
    private var amountRowEditing: some View {
        row(title: String(localized: "Amount"), icon: "number") {
            TextField("0.00", text: $amountText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .fixedSize()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                .focused($focusedField, equals: .expenseDetailAmount)
                .accessibilityLabel("Expense amount")
                .accessibilityHint("Enter the cost amount using decimal format")
                .accessibilityValue(amountText.isEmpty ? "No amount entered" : "\(amountText) \(userSettings.currencyCode)")
                .onChange(of: amountText) { _, newValue in
                    if let number = Self.amountParseFormatter.number(from: newValue) {
                        draft.amount = max(0, number.doubleValue)
                    } else {
                        draft.amount = 0
                    }
                }
                .onChange(of: focusedField) { _, _ in
                    if focusedField != .expenseDetailAmount {
                        amountText = draft.amount > 0
                            ? (Self.amountDisplayFormatter.string(from: NSNumber(value: draft.amount)) ?? "")
                            : ""
                    }
                }
                .onAppear {
                    amountText = draft.amount > 0
                        ? (Self.amountDisplayFormatter.string(from: NSNumber(value: draft.amount)) ?? "")
                        : ""
                }
        }
    }
    
    @ViewBuilder
    private var amountRowShowing: some View {
        row(title: String(localized: "Amount"), icon: "number") {
            if let amount = expense?.amount {
                if amount == 0 {
                    Text("0.00")
                        .foregroundStyle(.secondary)
                        .fontDesign(.rounded)
                        .accessibilityLabel("Amount: No amount set")
                } else {
                    Text(amount, format: .currency(code: userSettings.currencyCode))
                        .fontDesign(.rounded)
                        .accessibilityLabel("Amount: \(amount, format: .currency(code: userSettings.currencyCode))")
                }
            }
        }
    }
    
    // MARK: Active
    
    @ViewBuilder
    private var activeRowEditing: some View {
        row(title: String(localized: "Active"), icon: "lightbulb") {
            Toggle("", isOn: Binding(
                get: { draft.date != Date.distantPast },
                set: { newValue in
                    withAnimation(.snappy) {
                        draft.date = newValue ? Date.now : Date.distantPast
                    }
                }))
            .controlSize(.small)
        }
    }
    
    @ViewBuilder
    private var dueRowEditing: some View {
        row(title: String(localized: "Next Due"), icon: "calendar") {
            DatePicker("", selection: $draft.date, displayedComponents: [.date])
                .labelsHidden()
                .controlSize(.small)
                .accessibilityLabel("Expense date")
                .accessibilityHint("Select the date for this expense")
                .accessibilityValue(draft.date.formatted(date: .abbreviated, time: .omitted))
                .focused($focusedField, equals: .expenseDueDate)
        }
    }
    
    @ViewBuilder
    private var dueRowShowing: some View {
        row(title: String(localized: "Next Due"), icon: "calendar.badge.exclamationmark") {
            if let date = expense?.date {
                Text(date, style: .date)
                    .accessibilityLabel("Date: \(date.formatted(date: .abbreviated, time: .omitted))")
            }
        }
    }
    
    // MARK: Repeat
    
    @ViewBuilder
    private var repeatRowEditing: some View {
        row(title: String(localized: "Repeat"), icon: "arrow.trianglehead.counterclockwise") {
            Toggle("", isOn: Binding(
                get: { draft.frequencyValue != 0 },
                set: { newValue in
                    withAnimation(.snappy) {
                        draft.frequencyValue = newValue ? 1 : 0
                    }
                }))
            .controlSize(.small)
        }
    }
    
    @ViewBuilder
    private var frequencyRowEditing: some View {
        row(title: String(localized: "Frequency"), icon: "clock.arrow.trianglehead.counterclockwise.rotate.90") {
            Button {
                showFrequencyPicker = true
            } label: {
                Text(draft.frequencyUnit.displayText(for: draft.frequencyValue))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Frequency: \(draft.frequencyUnit.displayText(for: draft.frequencyValue))")
                    .accessibilityHint("Opens frequency picker")
            }
            .sheet(isPresented: $showFrequencyPicker) {
                frequencyPicker
            }
        }
    }
    
    
    @ViewBuilder
    private var repeatRowShowing: some View {
        row(title: String(localized: "Repeat"), icon: "arrow.trianglehead.counterclockwise") {
            Text(draft.frequencyUnit.displayText(for: draft.frequencyValue))
                .accessibilityLabel("Frequency: \(draft.frequencyUnit.displayText(for: draft.frequencyValue))")
        }
    }
    
    // MARK: Category Section

    @ViewBuilder
    private var categoryRowEditing: some View {
        row(title: String(localized: "Category"), icon: "archivebox") {
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
                    if store.canAddCategory(currentCount: categories.count) {
                        let draft = CategoryDraft.createNew(
                            sortOrder: (categories.last?.sortOrder ?? 0) + 1
                        )
                        uiState.createCategory(from: draft)
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label("New Category", systemImage: "plus")
                }
            } label: {
                if let category = draft.category {
                    HStack(spacing: 4) {
                        Image(systemName: category.iconName)
                        Text(category.name)
                    }
                    .foregroundStyle(category.color)
                } else {
                    Text("Select Category")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (draft.category?.color ?? .gray).opacity(0.18),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Expense category")
            .accessibilityHint("Select a category for this expense")
            .accessibilityValue(draft.category?.name ?? "No category selected")
        }
    }
        
    @ViewBuilder
    private var categoryRowShowing: some View {
        row(title: String(localized: "Category"), icon: "archivebox") {
            if let name = expense?.categoryName, let icon = expense?.categoryIconName {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                    Text(name)
                }
                .foregroundStyle(expense?.categoryColor ?? .primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (expense?.categoryColor ?? .gray).opacity(0.18),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .accessibilityLabel("Category: \(name)")
            }
        }
    }
    
    @ViewBuilder
    private var accountRowEditing: some View {
        row(title: String(localized: "Account"), icon: "person.2") {
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
                    uiState.createAccount(from: draft)
                } label: {
                    Label("New Account", systemImage: "plus")
                }
            } label: {
                if let account = draft.account {
                    HStack(spacing: 4) {
                        Image(systemName: account.iconName)
                        Text(account.name)
                    }
                } else {
                    Text("Select Account")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Expense account")
            .accessibilityHint("Select an account for this expense")
            .accessibilityValue(draft.account?.name ?? "No account selected")
        }
    }
    
    @ViewBuilder
    private var accountRowShowing: some View {
        row(title: String(localized: "Account"), icon: "person.2") {
            if let name = expense?.account?.name, let icon = expense?.account?.iconName {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                    Text(name)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Account: \(name)")
            }
        }
    }
    
    // MARK: Notes Section

    private var notesSectionEditing: some View {
        Section("Notes") {
            TextEditor(text: $draft.notes)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .focused($focusedField, equals: .expenseDetailNotes)
                .accessibilityLabel("Expense notes")
                .accessibilityHint("Add optional notes or details about this expense")
                .accessibilityValue(draft.notes.isEmpty ? "No notes" : draft.notes)
        }
    }

    @ViewBuilder
    private var notesSectionShowing: some View {
        if let notes = expense?.notes, !notes.isEmpty {
            Section("Notes") {
                Text(notes)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel("Notes: \(notes)")
            }
        }
    }

    @ViewBuilder
    private var inactiveInfo: some View {
        ContentUnavailableView(
            "Expense Inactive",
            systemImage: "info.circle.fill",
            description: Text("Edit this Expense and add a date to it in order to make it active again"))
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .accessibilityLabel("Expense is inactive")
        .accessibilityHint("Edit this Expense and add a date to it in order to make it active again")
    }

    @ViewBuilder
    private var markAsPaidButton: some View {
        Button {
            if let e = expense {
                switch e.type {
                case .oneTime, .inactive:
                    e.date = .distantPast
                    draft.date = .distantPast
                case .recurring:
                    e.advanceDueDate()
                    draft.date = e.date
                }
                try? context.save()
                uiState.showMarkedAsPaidConfirmation(owner: .inspector)
            }
        } label: {
            HStack {
                Image(systemName: "checkmark")
                Text("Mark as paid")
                    .fontWeight(.semibold)
            }
            .tintedActionButton(.green)
        }
        .accessibilityLabel("Mark expense as paid")
        .accessibilityHint("Mark this expense as paid and update its status")
    }
    
    private var statisticsSection: some View {
        Section("Statistics") {
            HStack {
                CostCard(title: String(localized: "Yearly"), amount: expense?.yearlyCost ?? 0)
                CostCard(title: String(localized: "Monthly"), amount: expense?.monthlyCost ?? 0)
                CostCard(title: String(localized: "Weekly"), amount: expense?.weeklyCost ?? 0)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Cost breakdown")
        }
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
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
            .tintedActionButton(.red)
        }
        .accessibilityLabel("Delete expense")
        .accessibilityHint("Permanently delete this expense. This action cannot be undone.")
        .alert("Delete Expense?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let expense = expense {
                    context.delete(expense)
                }
                successHaptic += 1
                dismiss()
                uiState.showDeletedPopup(owner: .main)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let title = expense?.title, !title.isEmpty {
                Text("\"\(title)\" will be permanently deleted.")
            } else {
                Text("This expense will be permanently deleted.")
            }
        }
    }

    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .cancellationAction) { cancelButton }
            ToolbarItem(placement: .confirmationAction) { saveButton }
        } else {
            if isPresentedAsSheet {
                ToolbarItem(placement: .cancellationAction) { closeButton }
            }
            ToolbarItem(placement: .confirmationAction) { editButton }
        }
    }
    
    private var cancelButton: some View {
        Button {
            switch initialState {
            case .edit(_), .view(_):
                isEditing = false
            case .new:
                dismiss()
            }
        } label: {
            Label("Cancel", systemImage: "xmark")
        }
        .accessibilityLabel("Cancel editing")
        .accessibilityHint("Discard changes and return to view mode")
    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Label("Close", systemImage: "chevron.down")
        }
        .accessibilityLabel("Close expense details")
        .accessibilityHint("Return to the previous screen")
    }
    
    private var saveButton: some View {
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
                successHaptic += 1
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
    }
    
    private var editButton: some View {
        Button {
             isEditing = true
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .accessibilityLabel("Edit expense")
        .accessibilityHint("Switch to edit mode to modify this expense")
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private var hiddenEmojiTextField: some View {
        TextField("", text: $emojiInput)
            .keyboardType(UIKeyboardType(rawValue: 124) ?? .default)
            .focused($focusedField, equals: .expenseEmojiKeyboard)
            .opacity(0)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onChange(of: emojiInput) { _, newValue in
                guard !newValue.isEmpty else { return }
                
                if let lastChar = newValue.last, lastChar.isEmoji {
                    draft.customImageData = String(lastChar).data(using: .utf8)
                    
                    focusedField = .none
                }
                
                emojiInput = ""
            }
    }
    
    @ViewBuilder
    private var frequencyPicker: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showFrequencyPicker = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
    }
    
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
                .font(.callout)
            Spacer()
            content()
        }
        .frame(minHeight: 30)
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        ExpenseInspector(initialState: .view(SampleData.oneTime))
    }
}
