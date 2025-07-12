//
//  TimelineView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    // MARK: - Properties
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date) private var expenses: [Expense]
    @Query private var categories: [ExpenseCategory]
    
    // User Settings
    @AppStorage(AppSettings.currencyKey) private var currencyCode: String = "EUR"
    
    // State
    @State private var activeSheet: ActiveSheet?
    @State private var showingSettings = false
    @State private var selectedFilter: FilterOption = .nonZero
    @State private var selectedViewMode: ViewMode = .normal
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
                            ExpenseDetailView(expense: expense)
                        }
                    case .new(let expense):
                        NavigationStack {
                            ExpenseDetailView(expense: expense, isEditingInitial: true) {
                                context.insert(expense)
                            }
                        }
                    case .edit(let expense):
                        NavigationStack {
                            ExpenseDetailView(expense: expense, isEditingInitial: true)
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
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
            ContentUnavailableView("No Expenses",
                                   systemImage: "list.bullet.clipboard",
                                   description: Text("Tap the + button to add your first expense."))
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
                        Text(group.totalAmount, format: .currency(code: currencyCode))
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
            switch selectedViewMode {
            case .compact:
                expense.createCompactRow(convertedAmount: expense.amount, currencyCode: currencyCode)
            case .normal:
                expense.createNormalRow(subtitle: subtitle, convertedAmount: expense.amount, currencyCode: currencyCode)
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
                    markAsPaid(expense)
                } label: {
                    Label("Mark as Paid", systemImage: "checkmark")
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    markAsPaid(expense)
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
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        
        ToolbarItem() {
                Menu {
                    Picker(selection: $selectedFilter) {
                        ForEach(FilterOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    } label: {
                        Label("Filter By", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .pickerStyle(.menu)
                    
                    Picker(selection: $selectedViewMode) {
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
        ToolbarSpacer(.fixed)
        
        ToolbarItem() {
            Button {
                let new = Expense.createNew(with: context)
                activeSheet = .new(new)
            } label: {
                Label("Add Expense", systemImage: "plus")
            }
        }
    }

    // MARK: - Data Processing
        
    /// A struct to hold the processed data for each month's expenses.
    private struct MonthlyExpenseGroup: Identifiable {
        let id: Date // The month can serve as a unique ID
        var month: Date
        var expenses: [Expense]
        var totalAmount: Double
    }
    
    /// Groups expenses by month, calculates the total amount for each month, and sorts the results.
    private var monthlyGroups: [MonthlyExpenseGroup] {
        // Apply filters to expenses (like in ListView)
        let filteredExpenses = ExpenseUtils.applyFilters(expenses, filter: selectedFilter)
        // 1. Group expenses by the start of their month.
        let groupedByMonth = Dictionary(grouping: filteredExpenses) { expense in
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: expense.date))!
        }
        // 2. Transform the grouped dictionary into an array of `MonthlyExpenseGroup`.
        return groupedByMonth.map { (month, expensesInMonth) in
            // Calculate the sum of amounts for all expenses in this month.
            let total = expensesInMonth.reduce(0) { $0 + $1.amount }
            let sortedExpenses = expensesInMonth.sorted { $0.date < $1.date }
            return MonthlyExpenseGroup(id: month, month: month, expenses: sortedExpenses, totalAmount: total)
        }
        // 3. Sort the groups by month, so the newest appear at the top.
        .sorted { $0.month < $1.month }
    }

    /// A shared formatter for displaying month and year in section headers.
    /// Using a computed property is more efficient than creating it inside the body.
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    /// Advances the expense's date based on its frequency.
    /// This is the business logic for the "Paid" swipe action.
    private func markAsPaid(_ expense: Expense) {
        withAnimation {
            let calendar = Calendar.current
            var dateComponent: Calendar.Component
            
            switch expense.frequencyUnit {
            case .day: dateComponent = .day
            case .week: dateComponent = .weekOfYear
            case .month: dateComponent = .month
            case .year: dateComponent = .year
            }
            
            if let newDate = calendar.date(byAdding: dateComponent, value: Int(expense.frequencyValue), to: expense.date) {
                expense.date = newDate
                try? context.save()
                listRefreshID = UUID()
            }
        }
    }
}
