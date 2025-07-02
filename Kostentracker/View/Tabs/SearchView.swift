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
    @AppStorage(AppSettings.currencyKey) private var currencyCode: String = "EUR"
    
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
                        ExpenseDetailView(expense: expense)
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
            List(searchResults) { expense in
                resultRow(for: expense)
            }
        }
    }
    
    /// A view for displaying a single search result row.
    private func resultRow(for expense: Expense) -> some View {
        HStack {
            if let imageData = expense.customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                // Fallback to the category icon
                Image(systemName: expense.category.iconName)
                    .font(.title2)
                    .frame(width: 40)
            }
            
            VStack(alignment: .leading) {
                Text(expense.title)
                    .font(.headline)
                HStack() {
                    Text(expense.date , style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Every \(expense.frequencyValue) \(expense.frequencyUnit.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(3)
            }
            
            Spacer()
            
            Text(expense.amount, format: .currency(code: currencyCode))
                .fontWeight(.medium)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedExpense = expense
        }
    }
}
