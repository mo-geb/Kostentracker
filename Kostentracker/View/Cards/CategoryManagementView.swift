//
//  CategoryManagementView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ExpenseCategory.name) private var categories: [ExpenseCategory]
    
    @State private var selectedCategory: ExpenseCategory?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(categories) { category in
                    categoryRow(for: category)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Manage Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let newCategory = ExpenseCategory(name: "", iconName: "tag", color: .blue)
                    context.insert(newCategory)
                    selectedCategory = newCategory
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
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
    
    // MARK: - View Components
    
    @ViewBuilder
    private func categoryRow(for category: ExpenseCategory) -> some View {
        HStack(spacing: 16) {
            // Category icon with circular background
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundStyle(category.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if category.isDefault {
                        Text("Default")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.secondary)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                
                Text("\(category.expenses?.count ?? 0) expenses")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Visual indicator that it's tappable
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCategory = category
        }
        .swipeActions(allowsFullSwipe: !category.isDefault) {
            if !category.isDefault {
                Button("Delete", role: .destructive) {
                    selectedCategory = category
                    showingDeleteAlert = true
                }
            }
        }
    }
}
