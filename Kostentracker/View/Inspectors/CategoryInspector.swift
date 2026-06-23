import SwiftUI
import SwiftData

struct CategoryInspector: View {
    // MARK: - Properties
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // State
    @State private var initialState: ActiveCategorySheet
    @State private var category: ExpenseCategory?
    @State private var draft: CategoryDraft
    @State private var showingDeleteAlert = false
    @State private var successHaptic = 0
    
    // Focus management
    @FocusState private var focusedField: FocusedField?
    
    // A list of sample icons for the user to choose from.
    private let sampleIcons = [
        "cart", "house", "car", "popcorn", "shield",
        "dumbbell", "bolt", "tag", "airplane", "gift",
        "pills", "fork.knife", "graduationcap", "suitcase", "gamecontroller",
        "heart", "music.note", "person.3", "wineglass", "book",
        "tshirt", "dog", "cat", "beach.umbrella", "laptopcomputer"
    ]
    
    private let iconGridColumns: [GridItem] = [
        .init(.adaptive(minimum: 50))
    ]
    
    // Initializer for editing or creating
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
            ScrollView {
                VStack(spacing: 20) {
                    detailsSection
                    iconSection
                    defaultButton
                    
                    if let category = category, !category.isDefault {
                        deleteButton
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .sensoryFeedback(.impact(weight: .light), trigger: draft.iconName)
            .sensoryFeedback(.impact(weight: .medium), trigger: draft.isDefault)
            .sensoryFeedback(.success, trigger: successHaptic)
            .navigationTitle((category?.name ?? draft.name).isEmpty ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .onTapGesture {
                focusedField = nil
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
    
    // MARK: - View Components
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack(spacing: 15) {
            inspectorRow(title:String(localized: "Name"), icon: "character.textbox") {
                TextField("Category Name", text: $draft.name)
                    .multilineTextAlignment(.trailing)
                    .fixedSize()
                    .padding(8)
                    .background(Color.gray.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                    .onChange(of: draft.name) { _, newValue in
                        if newValue.count > 20 {
                            draft.name = String(newValue.prefix(20))
                        }
                    }
                    .focused($focusedField, equals: .categoryDetailTitle)
            }
            
            inspectorRow(title:String(localized: "Color"), icon: "paintpalette") {
                ColorPicker("", selection: Binding(
                    get: { Color(hex: draft.hexColor) },
                    set: { draft.hexColor = $0.toHex() ?? "000000" }
                ))
                .labelsHidden()
                .accessibilityLabel("Category color")
            }
        }
    }
    
    @ViewBuilder
    private var iconSection: some View {
        VStack(alignment: .leading) {
            Text("Icon")
                .font(.headline)
                .padding(.leading)
            
            LazyVGrid(columns: iconGridColumns, spacing: 15) {
                ForEach(sampleIcons, id: \.self) { icon in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: draft.hexColor).opacity(0.3))

                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(Color(hex: draft.hexColor))
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: draft.hexColor), lineWidth: 2.5)
                            .opacity(draft.iconName == icon ? 1.0 : 0.0)
                    )
                    .onTapGesture {
                        if draft.iconName != icon { draft.iconName = icon }
                    }
                }
            }
            .padding()
            .cardSurface()
        }
    }
    
    @ViewBuilder
    private var defaultButton: some View {
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
        .padding(.vertical, 8)
        .disabled(draft.isDefault)
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
        .padding(.vertical, 8)
        .alert("Delete "\(draft.name)"?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let category = category {
                    category.deleteSafely(from: context)
                }
                successHaptic += 1
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Its expenses will be moved to the default category.")
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
                    if draft.isDefault {
                        ExpenseCategory.resetDefaultCategories(in: context)
                    }
                    category.update(from: draft)
                    
                case .new:
                    if draft.isDefault {
                        ExpenseCategory.resetDefaultCategories(in: context)
                    }
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
