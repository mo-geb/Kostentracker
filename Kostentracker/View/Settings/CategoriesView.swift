import SwiftUI
import SwiftData

struct CategoriesView: View {

    // MARK: - Properties
    // Shared
    @Environment(UIState.self) private var ui: UIState
    @Environment(StoreManager.self) private var store

    // SwiftData
    @Environment(\.modelContext) private var context
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    // State
    @State private var showingDeleteAlert = false
    @State private var showPaywall = false
    
    // MARK: - Body
    
    var body: some View {
        @Bindable var ui = ui
        
        NavigationStack {
            mainContent
                .navigationTitle("Manage Categories")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .sheet(item: $ui.activeCategorySheet) { sheet in
                    NavigationStack {
                        switch sheet {
                        case .new(let draft): CategoryInspector(initialState: .new(draft))
                        case .edit(let category): CategoryInspector(initialState: .edit(category))
                        }
                    }
                }
                .paywallSheet(isPresented: $showPaywall)
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            listSection
            addButton
        }
    }
    
    // MARK: - List Section
    
    @ViewBuilder
    private var listSection: some View {
        List {
            ForEach(categories) { category in
                categoryRow(for: category)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onMove(perform: moveCategory)
        }
        .listStyle(.plain)
    }
    
    // MARK: - Add Button
    
    @ViewBuilder
    private var addButton: some View {
        Button {
            if store.canAddCategory(currentCount: categories.count) {
                let draft = CategoryDraft.createNew(sortOrder: (categories.last?.sortOrder ?? 0) + 1)
                ui.createCategory(from: draft)
            } else {
                showPaywall = true
            }
        } label: {
            Label("Add Category", systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .cornerRadius(14)
                .padding([.horizontal, .top])
        }
        .frame(minHeight: 44)
        .accessibilityIdentifier("addCategoryButton")
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            EditButton()
        }
    }
    
    // MARK: - Move Support
    
    private func moveCategory(from source: IndexSet, to destination: Int) {
        var revised = categories
        revised.move(fromOffsets: source, toOffset: destination)
        for (index, category) in revised.enumerated() {
            category.sortOrder = index
        }
        do {
            try context.save()
        } catch {
            print("Failed to save reordered categories: \(error)")
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func categoryRow(for category: ExpenseCategory) -> some View {
        HStack(alignment: .center, spacing: 18) {
            // Category icon with rounded rectangle background
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(category.color.opacity(0.25))
                    .frame(width: 60, height: 60)
                Image(systemName: category.iconName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(category.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(category.name)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .layoutPriority(1)
                    .minimumScaleFactor(0.7)
                HStack(alignment: .center, spacing: 8) {
                    Text("\(category.expenses?.count ?? 0) expenses")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if category.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.secondary)
                            .cornerRadius(7)
                    }
                }
            }
            Spacer(minLength: 12)
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.systemGray3))
                .padding(.leading, 2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .glassyCard()
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            ui.editCategory(category)
        }
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        CategoriesView()
            .environment(UIState())
            .environment(UserSettings())
            .environment(StoreManager())
    }
}
