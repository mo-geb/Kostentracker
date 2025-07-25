//
//  CategoryManagementView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    
    // MARK: - Properties
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    // State
    @State private var activeSheet: ActiveCategorySheet?
    @State private var showingDeleteAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Manage Categories")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .new(let draft):
                        NavigationStack {
                            CategoryDetailView(initialState: .new(draft))
                        }
                    case .edit(let expense):
                        NavigationStack {
                            CategoryDetailView(initialState: .edit(expense))
                        }
                    }
                }
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
            }
            .onMove(perform: moveCategory)
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Add Button
    
    @ViewBuilder
    private var addButton: some View {
        Button {
            let draft = CategoryDraft.createNew(sortOrder: (categories.last?.sortOrder ?? 0) + 1)
            activeSheet = .new(draft)
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
                HStack(alignment: .center, spacing: 8) {
                    Text(category.name)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .layoutPriority(1)
                        .minimumScaleFactor(0.8)
                    if category.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.secondary)
                            .cornerRadius(7)
                    }
                }
                Text("\(category.expenses?.count ?? 0) expenses")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.systemGray3))
                .padding(.leading, 2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            activeSheet = .edit(category)
        }
    }
}
