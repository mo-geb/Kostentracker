//
//  CategoryEditorView.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 03.07.25.
//


//
//  CategoryEditorView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var category: ExpenseCategory
    
    @State private var showingDeleteAlert = false
    
    // A list of sample icons for the user to choose from.
    let sampleIcons = [
        "cart", "house", "car", "popcorn", "shield",
        "dumbbell", "bolt", "tag", "airplane", "gift",
        "pills", "fork.knife", "graduationcap", "suitcase", "gamecontroller"]
    
    // Define the grid layout for the icons.
    // .adaptive will create as many columns as can fit with a minimum size.
    // This creates a responsive grid that looks great on any device.
    private let iconGridColumns: [GridItem] = [
        .init(.adaptive(minimum: 50))
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    detailsSection
                    iconSection
                    
                    if !category.isDefault {
                        deleteButton
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(category.name.isEmpty ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
    }
    
    // MARK: - View Components
    
    /// Section for the category's name and color.
    @ViewBuilder
    private var detailsSection: some View {
        VStack(spacing: 15) {
            row(title: "Name") {
                if category.isDefault {
                    Text(category.name)
                } else {
                    TextField("Category Name", text: $category.name)
                        .multilineTextAlignment(.trailing)
                        .fixedSize()
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }
            
            row(title: "Color") {
                ColorPicker("", selection: Binding(
                    get: { category.color },
                    set: { category.hexColor = $0.toHex() ?? "000000" }
                ))
                .labelsHidden()
            }
        }
    }
    
    /// Section for the icon selection grid.
    @ViewBuilder
    private var iconSection: some View {
        VStack(alignment: .leading) {
            Text("Icon")
                .font(.headline)
                .padding(.leading)
            
            LazyVGrid(columns: iconGridColumns, spacing: 15) {
                ForEach(sampleIcons, id: \.self) { icon in
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.3))

                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(category.color)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Circle()
                            .stroke(category.color, lineWidth: 2.5)
                            .opacity(category.iconName == icon ? 1.0 : 0.0)
                    )
                    .onTapGesture {
                        category.iconName = icon
                    }
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(.red)
        .alert("Delete Category?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                category.deleteSafely(from: context)
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
                // If this is a new category that hasn't been saved yet, delete it
                if category.name.isEmpty {
                    context.delete(category)
                }
                dismiss()
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                dismiss()
            } label: {
                Label("Save", systemImage: "checkmark")
            }
            .disabled(category.name.isEmpty)
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
