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
    @State private var listRefreshID = UUID()

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Timeline")
                .toolbar { toolbarContent }
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
        
        return ExpenseRow(expense: expense, subtitle: subtitle, tab: .timeline)
            .contentShape(Rectangle())
            .onTapGesture { ui.viewExpense(expense) }
            .contextMenu {
                Button {
                    ui.editExpense(expense)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .accessibilityLabel("Edit expense")
                .accessibilityHint("Opens expense for editing")
                
                Button {
                    switch expense.type {
                    case .oneTime, .inactive:
                        context.delete(expense)
                    case .recurring:
                        expense.advanceDueDate()
                        ui.showMarkedAsPaidConfirmation(owner: ActivePopup.MarkedAsPaidOwner.main)
                    }
                   
                    try? context.save()
                    listRefreshID = UUID()
                } label: {
                    Label("Mark as paid", systemImage: "checkmark")
                }
                .accessibilityLabel("Mark as paid")
                .accessibilityHint("Marks this expense as paid")
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    switch expense.type {
                    case .oneTime, .inactive:
                        context.delete(expense)
                    case .recurring:
                        expense.advanceDueDate()
                        ui.showMarkedAsPaidConfirmation(owner: ActivePopup.MarkedAsPaidOwner.main)
                    }
                   
                    try? context.save()
                    listRefreshID = UUID()
                } label: {
                    Label("Paid", systemImage: "checkmark")
                }
                .tint(.green)
                .accessibilityLabel("Mark as paid")
                .accessibilityHint("Marks this expense as paid")
            }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            SharedToolbarElements.SettingsButton()
        }
        
        ToolbarItem() {
            SharedToolbarElements.OptionsMenu {
                SharedToolbarElements.FilterPicker()
                SharedToolbarElements.ViewModePicker()
            }
        }
        
        ToolbarItem() {
            SharedToolbarElements.AddExpenseButton()
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
        let filteredExpenses = Expense.applyCustomFilters(expenses, filter: ui.selectedFilter)
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
