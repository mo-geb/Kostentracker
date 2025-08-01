import SwiftUI
import SwiftData

struct TimelineView: View {
    // MARK: - Properties
    // Shared
    @EnvironmentObject var ui: UIState
    @EnvironmentObject var userSettings: UserSettings
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date) private var expenses: [Expense]
    @Query private var categories: [ExpenseCategory]
    
    // State
    @State private var activeSheet: ActiveExpenseSheet?
    @State private var listRefreshID = UUID()

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Timeline")
                .toolbar { toolbarContent }
                .sheet(item: $activeSheet) { sheet in
                    switch sheet {
                    case .view(let expense):
                        NavigationStack {
                            ExpenseDetailView(initialState: .view(expense))
                        }
                    case .new(let draft):
                        NavigationStack {
                            ExpenseDetailView(initialState: .new(draft))
                        }
                    case .edit(let expense):
                        NavigationStack {
                            ExpenseDetailView(initialState: .edit(expense))
                        }
                    }
                }
                .sheet(isPresented: $ui.showingSettings) {
                    SettingsView()
                }
        }
    }
    
    // MARK: - View Components
    
    /// The main content of the view, showing a message if there are no expenses,
    /// or the list of expenses grouped by month.
    @ViewBuilder
    private var mainContent: some View {
        if expenses.isEmpty {
            EmptyExpensesView()
        } else {
            expenseList
        }
    }
    
    /// The list that displays expenses, grouped into sections by month.
    private var expenseList: some View {
        List {
            ForEach(monthlyGroups) { group in
                Section {
                    ForEach(group.expenses) { expense in
                        expenseRow(for: expense)
                    }
                } header: {
                    HStack {
                        Text(group.month, formatter: monthFormatter)
                        Spacer()
                        Text(group.totalAmount, format: .currency(code: userSettings.currencyCode))
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .id(listRefreshID)
    }
    
    /// A view representing a single row in the expense list.
    private func expenseRow(for expense: Expense) -> some View {
        let subtitle = DateFormatter.localizedString(from: expense.date, dateStyle: .medium, timeStyle: .none)
        
        @ViewBuilder
        var rowContent: some View {
            switch ui.selectedViewMode {
            case .compact:
                expense.createCompactRow(convertedAmount: expense.amount, currencyCode: userSettings.currencyCode)
            case .normal:
                expense.createNormalRow(subtitle: subtitle, convertedAmount: expense.amount, currencyCode: userSettings.currencyCode, displayTotal: true)
            }
        }
        
        return rowContent
            .contentShape(Rectangle())
            .onTapGesture { activeSheet = .view(expense) }
            .contextMenu {
                Button {
                    activeSheet = .edit(expense)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    expense.markAsPaid()
                    try? context.save()
                    listRefreshID = UUID()
                } label: {
                    Label("Mark as paid", systemImage: "checkmark")
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    expense.markAsPaid()
                    try? context.save()
                    listRefreshID = UUID()
                } label: {
                    Label("Paid", systemImage: "checkmark")
                }
                .tint(.green)
            }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                ui.showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        
        ToolbarItem() {
                Menu {
                    Picker(selection: $ui.selectedFilter) {
                        ForEach(FilterOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    } label: {
                        Label("Filter By", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .pickerStyle(.menu)
                    
                    Picker(selection: $ui.selectedViewMode) {
                        ForEach(ViewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    } label: {
                        Label("View Mode", systemImage: "list.bullet.rectangle")
                    }
                    .pickerStyle(.segmented)
                    
                } label: {
                    Label("Options", systemImage: "ellipsis")
                }
            }
//        if #available(iOS 26.0, *) {
//            ToolbarSpacer(.fixed)
//        }
        
        ToolbarItem() {
            Button {
                activeSheet = .new(ExpenseDraft.createNew(with: context))
            } label: {
                Label("Add Expense", systemImage: "plus")
            }
        }
    }

    // MARK: - Data Processing
        
    /// A struct to hold the processed data for each month's expenses.
    private struct MonthlyExpenseGroup: Identifiable {
        let id: Date
        var month: Date
        var expenses: [Expense]
        var totalAmount: Double
    }
    
    /// Groups expenses by month, calculates the actual amounts due in each month, and sorts the results.
    private var monthlyGroups: [MonthlyExpenseGroup] {
        let filteredExpenses = Utils.applyFilters(expenses, filter: ui.selectedFilter)
        let calendar = Calendar.current
        
        // 1. Group expenses by the start of their month
        let groupedByMonth = Dictionary(grouping: filteredExpenses) { expense in
            calendar.date(from: calendar.dateComponents([.year, .month], from: expense.date))!
        }
        
        // 2. Transform the grouped dictionary into an array of MonthlyExpenseGroup
        return groupedByMonth.map { (month, expensesInMonth) in
            // For each month, calculate the total using the new method
            let total = expensesInMonth.reduce(0.0) { sum, expense in
                sum + expense.totalForMonth(containing: month)
            }
            
            let sortedExpenses = expensesInMonth.sorted { $0.date < $1.date }
            return MonthlyExpenseGroup(id: month, month: month, expenses: sortedExpenses, totalAmount: total)
        }
        // 3. Sort the groups by month, so the newest appear at the top
        .sorted { $0.month < $1.month }
    }

    /// A shared formatter for displaying month and year in section headers.
    /// Using a computed property is more efficient than creating it inside the body.
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: Expense.self, ExpenseCategory.self)
        let context = container.mainContext
        
        #if DEBUG
        print("Entered App in DEBUG... Deleting models")
        try? context.delete(model: Expense.self)
        try? context.delete(model: ExpenseCategory.self)

        UserDefaults.standard.removeObject(forKey: "hasCreatedDefaultCategories")
        #endif
        
        UserDefaults.standard.removeObject(forKey: "hasCreatedDefaultCategories")
        
        SampleData.categories.forEach {
            container.mainContext.insert($0)
        }
        
        SampleData.expenses.forEach {
            container.mainContext.insert($0)
        }
        
        return NavigationStack {
            TimelineView()
                .modelContainer(container)
                .environmentObject(UIState())
                .environmentObject(UserSettings())
        }
        
    } catch {
        return Text("Failed to create preview container: \(error.localizedDescription)")
    }
}
