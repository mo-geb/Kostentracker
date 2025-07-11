//
//  CategoryManagementView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    @State private var selectedCategory: ExpenseCategory?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(categories) { category in
                    categoryRow(for: category)
                }
                .onMove(perform: moveCategory)
            }
            .listStyle(.insetGrouped)
            
            Button {
                let newCategory = ExpenseCategory(name: "", iconName: "tag", color: .blue, sortOrder: (categories.last?.sortOrder ?? 0) + 1)
                context.insert(newCategory)
                selectedCategory = newCategory
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
        .navigationTitle("Manage Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $selectedCategory) { category in
            CategoryDetailView(category: category)
        }
        .alert("Delete Category?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let category = selectedCategory {
                    category.deleteSafely(from: context)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure? This action cannot be undone.")
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
            selectedCategory = category
        }
        .swipeActions(allowsFullSwipe: !category.isDefault) {
            if !category.isDefault {
                Button(role: .destructive) {
                    selectedCategory = category
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
