//
//  SearchView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct SearchView: View {
    
    // MARK: - Properties
    
    /// The user's current search query.
    @State private var searchText = ""

    @Query private var allExpenses: [Expense]
    @AppStorage(UserSettings.currencyKey) private var currencyCode: String = "EUR"
    
    /// The expense selected by the user to view its details.
    @State private var selectedExpense: Expense?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Search")
                .searchable(text: $searchText, prompt: "Search by title or notes")
                .sheet(item: $selectedExpense) { expense in
                    NavigationStack {
                        ExpenseDetailView(initialState: .view(expense))
                    }
                }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Filters the expenses based on the `searchText`.
    /// The search is case-insensitive and checks both the title and notes.
    private var searchResults: [Expense] {
        if searchText.isEmpty {
            return []
        }
        
        return allExpenses.filter { expense in
            let titleMatch = expense.title.localizedCaseInsensitiveContains(searchText)
            let notesMatch = expense.notes.localizedCaseInsensitiveContains(searchText)
            return titleMatch || notesMatch
        }
    }
    
    // MARK: - View Components
    
    /// The main content of the view, which changes based on the search state.
    @ViewBuilder
    private var content: some View {
        if searchText.isEmpty {
            ContentUnavailableView("Search for Expenses", systemImage: "magnifyingglass")
            
        } else if searchResults.isEmpty {
            ContentUnavailableView.search(text: searchText)
            
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(searchResults) { expense in
                        resultRow(for: expense)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    /// A view for displaying a single search result row.
    private func resultRow(for expense: Expense) -> some View {
        HStack(spacing: 16) {
            // Category icon with app-shaped background for custom images, circular for system icons
            if let imageData = expense.customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    Circle()
                        .fill(expense.categoryColor.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: expense.categoryIconName)
                        .font(.title2)
                        .foregroundStyle(expense.categoryColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(expense.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(expense.frequencyUnit.displayName(for: expense.frequencyValue))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(expense.amount, format: .currency(code: currencyCode))
                .fontWeight(.medium)
        }
        .padding(16)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedExpense = expense
        }
    }
}
