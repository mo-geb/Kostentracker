import SwiftUI
import SwiftData

struct CategoryInspector: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var initialState: ActiveCategorySheet
    @State private var category: ExpenseCategory?
    @State private var draft: CategoryDraft
    @State private var showingDeleteAlert = false
    @State private var successHaptic = 0

    @FocusState private var focusedField: FocusedField?

    private let sampleIcons = [
        "cart", "house", "car", "popcorn", "shield",
        "dumbbell", "bolt", "tag", "airplane", "gift",
        "pills", "fork.knife", "graduationcap", "suitcase", "gamecontroller",
        "heart", "music.note", "person.3", "wineglass", "book",
        "tshirt", "dog", "cat", "beach.umbrella", "laptopcomputer"
    ]

    private let iconGridColumns: [GridItem] = [.init(.adaptive(minimum: 50))]

    init(initialState: ActiveCategorySheet) {
        self.initialState = initialState
        switch initialState {
        case .edit(let c):
            self.category = c
            self._draft = State(initialValue: CategoryDraft(from: c))
        case .new(let d):
            self._category = State(initialValue: nil)
            self._draft = State(initialValue: d)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                iconSection
                defaultSection

                if let category = category, !category.isDefault {
                    deleteSection
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .sensoryFeedback(.impact(weight: .light), trigger: draft.iconName)
            .sensoryFeedback(.impact(weight: .medium), trigger: draft.isDefault)
            .sensoryFeedback(.success, trigger: successHaptic)
            .navigationTitle((category?.name ?? draft.name).isEmpty ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if case .new(_) = initialState {
                    Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        focusedField = .categoryDetailTitle
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section {
            HStack {
                Image(systemName: "character.textbox")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(width: 20)
                Text("Name")
                    .font(.callout)
                Spacer()
                TextField("Category Name", text: $draft.name)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: draft.name) { _, newValue in
                        if newValue.count > 20 { draft.name = String(newValue.prefix(20)) }
                    }
                    .focused($focusedField, equals: .categoryDetailTitle)
            }
            .frame(minHeight: 30)

            HStack {
                Image(systemName: "paintpalette")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(width: 20)
                Text("Color")
                    .font(.callout)
                Spacer()
                ColorPicker("", selection: Binding(
                    get: { Color(hex: draft.hexColor) },
                    set: { draft.hexColor = $0.toHex() ?? "000000" }
                ))
                .labelsHidden()
                .accessibilityLabel("Category color")
            }
            .frame(minHeight: 30)
        }
    }

    private var iconSection: some View {
        Section("Icon") {
            LazyVGrid(columns: iconGridColumns, spacing: 15) {
                ForEach(sampleIcons, id: \.self) { icon in
                    let color = Color(hex: draft.hexColor)
                    let isSelected = draft.iconName == icon
                    Button {
                        if !isSelected { draft.iconName = icon }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(color.opacity(0.3))
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(color)
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(color, lineWidth: 2.5)
                                .opacity(isSelected ? 1.0 : 0.0)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(icon)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .listRowInsets(.init(top: 15, leading: 15, bottom: 15, trailing: 15))
        }
    }

    private var defaultSection: some View {
        Section {
            Button {
                draft.isDefault = true
            } label: {
                HStack {
                    Image(systemName: draft.isDefault ? "checkmark.seal.fill" : "star")
                    Text(draft.isDefault ? (category?.isDefault == true ? "Default" : "Will be Default") : "Make Default")
                        .fontWeight(.semibold)
                }
                .tintedActionButton(draft.isDefault ? .gray : .accentColor)
            }
            .disabled(draft.isDefault)
            .listRowBackground(Color.clear)
            .listRowInsets(.init())
        }
    }

    private var deleteSection: some View {
        Section {
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
            .listRowBackground(Color.clear)
            .listRowInsets(.init())
            .alert("Delete \"\(draft.name)\"?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let category = category { category.deleteSafely(from: context) }
                    successHaptic += 1
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Its expenses will be moved to the default category.")
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            SharedToolbarElements.DismissButton()
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                switch initialState {
                case .edit(let category):
                    if draft.isDefault { ExpenseCategory.resetDefaultCategories(in: context) }
                    category.update(from: draft)
                case .new:
                    if draft.isDefault { ExpenseCategory.resetDefaultCategories(in: context) }
                    let newCategory = ExpenseCategory(from: draft)
                    context.insert(newCategory)
                    self.category = newCategory
                }
                do {
                    try context.save()
                    successHaptic += 1
                } catch {
                    print("Failed to save category: \(error)")
                }
                dismiss()
            } label: {
                Label("Save", systemImage: "checkmark")
            }
            .disabled(draft.name.isEmpty)
            .tint(.green)
        }
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        CategoryInspector(initialState: .edit(SampleData.subscription))
    }
}
