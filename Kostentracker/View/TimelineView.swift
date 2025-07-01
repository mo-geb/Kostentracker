//
//  TimelineView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    // MARK: - Properties
    
    // SwiftData Context and Query
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date) private var expenses: [Expense]
    
    // State for presenting sheets.
    @State private var selectedExpense: Expense?
    @State private var newExpense: Expense?

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Timeline")
                .toolbar { addExpenseToolbarItem }
                .sheet(item: $selectedExpense) { expense in
                    // Sheet for viewing details of an existing expense.
                    NavigationStack {
                        ExpenseDetailView(expense: expense)
                    }
                }
                .sheet(item: $newExpense) { expense in
                    // Sheet for creating a new expense.
                    NavigationStack {
                        ExpenseDetailView(expense: expense, isEditingInitial: true) {
                            context.insert(expense)
                        }
                    }
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
                        Text(group.totalAmount, format: .currency(code: "EUR"))
                    }
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    /// A view representing a single row in the expense list.
    @ViewBuilder
    private func expenseRow(for expense: Expense) -> some View {
        HStack {
            Image(systemName: expense.category.iconName)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(expense.title)
                    .font(.headline)
                Text(expense.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(expense.amount, format: .currency(code: "EUR"))
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedExpense = expense
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
    private var addExpenseToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                // Create a new, empty Expense object to pass to the sheet.
                newExpense = Expense(title: "", amount: 0, frequencyUnit: .months, frequencyValue: 1, date: Date(), category: .other, notes: "")
            } label: {
                Label("Add Expense", systemImage: "plus")
            }
        }
    }

    // MARK: - Data Processing Struct
        
    /// A struct to hold the processed data for each month's expenses.
    private struct MonthlyExpenseGroup: Identifiable {
        let id: Date // The month can serve as a unique ID
        var month: Date
        var expenses: [Expense]
        var totalAmount: Double
    }
    
    // MARK: - Computed Properties
    
    /// Groups expenses by month, calculates the total amount for each month, and sorts the results.
    private var monthlyGroups: [MonthlyExpenseGroup] {
        // 1. Group expenses by the start of their month.
        let groupedByMonth = Dictionary(grouping: expenses) { expense in
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: expense.date))!
        }
        
        // 2. Transform the grouped dictionary into an array of `MonthlyExpenseGroup`.
        return groupedByMonth.map { (month, expensesInMonth) in
            // Calculate the sum of amounts for all expenses in this month.
            let total = expensesInMonth.reduce(0) { $0 + $1.amount }
            return MonthlyExpenseGroup(id: month, month: month, expenses: expensesInMonth, totalAmount: total)
        }
        // 3. Sort the groups by month, so the newest appear at the top.
        .sorted { $0.month > $1.month }
    }

    /// A shared formatter for displaying month and year in section headers.
    /// Using a computed property is more efficient than creating it inside the body.
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    // MARK: - Methods
    
    /// Advances the expense's date based on its frequency.
    /// This is the business logic for the "Paid" swipe action.
    private func markAsPaid(_ expense: Expense) {
        let calendar = Calendar.current
        var dateComponent: Calendar.Component
        
        switch expense.frequencyUnit {
        case .days: dateComponent = .day
        case .weeks: dateComponent = .weekOfYear
        case .months: dateComponent = .month
        case .years: dateComponent = .year
        }

        if let newDate = calendar.date(byAdding: dateComponent, value: Int(expense.frequencyValue), to: expense.date) {
            expense.date = newDate
        }
    }
}
