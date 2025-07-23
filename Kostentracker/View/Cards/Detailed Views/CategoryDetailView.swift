//
//  CategoryEditorView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    // MARK: - Properties
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // State
    @State private var initialState: ActiveCategorySheet
    @State private var category: ExpenseCategory?
    @State private var draft: CategoryDraft
    @State private var showingDeleteAlert = false
    
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
            .background(Color(.systemGroupedBackground))
            .navigationTitle((category?.name ?? draft.name).isEmpty ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack(spacing: 15) {
            row(title: "Name") {
                TextField("Category Name", text: $draft.name)
                    .multilineTextAlignment(.trailing)
                    .fixedSize()
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .onChange(of: draft.name) { _, newValue in
                        if newValue.count > 20 {
                            draft.name = String(newValue.prefix(20))
                        }
                    }
            }
            
            row(title: "Color") {
                ColorPicker("", selection: Binding(
                    get: { Color(hex: draft.hexColor) },
                    set: { draft.hexColor = $0.toHex() ?? "000000" }
                ))
                .labelsHidden()
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
                        draft.iconName = icon
                    }
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private var defaultButton: some View {
        Button {
            if !draft.isDefault {
                draft.isDefault = true
            }
        } label: {
            HStack {
                Image(systemName: draft.isDefault ? "checkmark.seal.fill" : "star")
                Text(draft.isDefault ? (category?.isDefault == true ? "Default" : "Will be Default") : "Make Default")
                    .fontWeight(.semibold)
            }
            .foregroundColor(draft.isDefault ? .gray : .blue)
            .padding(.vertical, 14)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill((draft.isDefault ? Color.gray : Color.blue).opacity(0.15))
            )
        }
        .frame(maxWidth: 260)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal)
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
        .alert("Delete Category?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let category = category {
                    category.deleteSafely(from: context)
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
            Button { 
                dismiss()
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button {
                switch initialState {
                case .edit(let category):
                    // If making this category default, unset all others
                    if draft.isDefault {
                        let descriptor = FetchDescriptor<ExpenseCategory>()
                        if let allCategories = try? context.fetch(descriptor) {
                            for cat in allCategories where cat.id != category.id {
                                cat.isDefault = false
                            }
                        }
                    }
                    category.update(from: draft)
                    
                case .new:
                    // If making this new category default, unset all others
                    if draft.isDefault {
                        let descriptor = FetchDescriptor<ExpenseCategory>()
                        if let allCategories = try? context.fetch(descriptor) {
                            for cat in allCategories {
                                cat.isDefault = false
                            }
                        }
                    }
                    let newCategory = ExpenseCategory(from: draft)
                    context.insert(newCategory)
                    self.category = newCategory
                }
                do {
                    try context.save()
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
    
    // MARK: - Helper Views
    
    /// A generic row builder to reduce duplication, matching the style of ExpenseDetailView.
    @ViewBuilder
    private func row<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.callout)
            Spacer()
            content()
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
    }
    
}
