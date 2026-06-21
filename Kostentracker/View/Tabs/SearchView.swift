import SwiftUI
import SwiftData

struct SearchView: View {
    
    // MARK: - Properties
    // Shared
    @Environment(UserSettings.self) var userSettings

    // State
    @State private var searchText = ""
    @State private var detailRoute: ExpenseDetailRoute?

    @Query private var allExpenses: [Expense]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Search")
                .searchable(text: $searchText, prompt: "Search by title or notes")
                .expenseDetailDestination($detailRoute)
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
                .background(Color(.systemGroupedBackground))

        } else if searchResults.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(searchResults) { expense in
                        resultRow(for: expense)
                    }
                }
                .animation(.default, value: searchResults)
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    /// A view for displaying a single search result row.
    private func resultRow(for expense: Expense) -> some View {
        HStack(spacing: 16) {
            switch expense.displayMedia {
            case .image(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .emoji(let emoji, let color):
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 50, height: 50)
                    Text(emoji)
                        .font(.title)
                }
            case .icon(let name, let color):
                ZStack {
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 50, height: 50)
                    Image(systemName: name)
                        .font(.title2)
                        .foregroundStyle(color)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                switch expense.type {
                case .inactive:
                    Text("Inactive")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                case .oneTime, .recurring:
                    Text(expense.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(expense.frequencyUnit.displayText(for: expense.frequencyValue))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(expense.amount, format: .currency(code: userSettings.currencyCode))
                .fontWeight(.medium)
                .fontDesign(.rounded)
        }
        .padding(16)
        .cardSurface()
        .contentShape(Rectangle())
        .onTapGesture {
            detailRoute = ExpenseDetailRoute(expense: expense)
        }
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        SearchView()
            .environment(UIState())
            .environment(UserSettings())
    }
}
