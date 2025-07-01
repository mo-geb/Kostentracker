//
//  CategoryListView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct ListView: View {
    
    // MARK: - Properties
    
    @Environment(\.modelContext) private var context
    @Query private var expenses: [Expense]
    
    // MARK: - State for User Controls
    
    @State private var selectedExpense: Expense?
    @State private var newExpense: Expense?
    @State private var selectedPeriod: CostPeriod = .monthly
    @State private var selectedSort: SortOption = .dateDescending
    
    @State var searchText = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Categories")
                .toolbar { controlsToolbar }
                .sheet(item: $selectedExpense) { expense in
                    NavigationStack {
                        ExpenseDetailView(expense: expense)
                    }
                }
                .sheet(item: $newExpense) { expense in
                    NavigationStack {
                        ExpenseDetailView(expense: expense, isEditingInitial: true) {
                            context.insert(expense)
                        }
                    }
                }
        }
    }
    
    // MARK: - View Components
    
    /// The main view content, switching between the list and an empty state.
    @ViewBuilder
    private var mainContent: some View {
        if expenses.isEmpty {
            ContentUnavailableView(
                "No Expenses Found",
                systemImage: "tray",
                description: Text("Add expenses to see them grouped by category.")
            )
        } else {
            categoryList
        }
    }
    
    /// The list of expenses, sectioned by category.
    private var categoryList: some View {
        List {
            ForEach(processedCategories) { categoryData in
                Section {
                    ForEach(categoryData.expenses) { expense in
                        expenseRow(for: expense)
                    }
                } header: {
                    categoryHeader(for: categoryData)
                }
            }
        }
    }
    
    /// The header for each category section, showing the name and total cost.
    private func categoryHeader(for categoryData: ProcessedCategory) -> some View {
        HStack {
            Image(systemName: categoryData.category.iconName)
            Text(categoryData.category.rawValue.capitalized)
            Spacer()
            Text(categoryData.totalCost, format: .currency(code: "EUR"))
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
    
    /// A view for a single expense row.
    private func expenseRow(for expense: Expense) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(expense.title)
                    .font(.headline)
                Text("Every \(expense.frequencyValue) \(expense.frequencyUnit.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(convertCost(for: expense), format: .currency(code: "EUR"))
                .fontWeight(.medium)
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedExpense = expense
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var controlsToolbar: some ToolbarContent {
        ToolbarItem() {
                Menu {
                    Picker(selection: $selectedPeriod, label: Label("Display Period", systemImage: "calendar.badge.clock")) {
                        ForEach(CostPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.menu)
                    Picker(selection: $selectedSort, label: Label("Sort By", systemImage: "arrow.up.arrow.down")) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    
                } label: {
                    Label("Options", systemImage: "ellipsis")
                }
            }
        ToolbarSpacer(.fixed)
        ToolbarItem() {
                Button {
                    newExpense = Expense(title: "", amount: 0, frequencyUnit: .months, frequencyValue: 1, date: Date(), category: .other, notes: "")
                } label: {
                    Label("Add Expense", systemImage: "plus")
                }
            }
    }
    
    // MARK: - Data Processing
    
    /// A struct to hold the processed data for each category.
    private struct ProcessedCategory: Identifiable {
        let id: Category
        var category: Category
        var totalCost: Double
        var expenses: [Expense]
    }
    
    /// This is the core logic. It groups, sorts, and calculates costs based on user selections.
    private var processedCategories: [ProcessedCategory] {
        // 1. Group all expenses by their category.
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        
        // 2. Map over the grouped dictionary to process each category.
        let processed = grouped.map { (category, expenses) -> ProcessedCategory in
            // a. Calculate the total cost for this category based on the selected period.
            let total = expenses.reduce(0) { $0 + convertCost(for: $1) }
            
            // b. Sort the expenses within this category based on the selected sort option.
            let sortedExpenses = sort(expenses: expenses)
            
            return ProcessedCategory(id: category, category: category, totalCost: total, expenses: sortedExpenses)
        }
        
        // 3. Sort the categories themselves alphabetically.
        return processed.sorted { $0.category.rawValue < $1.category.rawValue }
    }
    
    /// Sorts an array of expenses based on the `selectedSort` state.
    private func sort(expenses: [Expense]) -> [Expense] {
        switch selectedSort {
        case .dateDescending:
            return expenses.sorted { $0.date > $1.date }
        case .dateAscending:
            return expenses.sorted { $0.date < $1.date }
        case .amountDescending:
            return expenses.sorted { calculateYearlyCost(for: $0) > calculateYearlyCost(for: $1) }
        case .amountAscending:
            return expenses.sorted { calculateYearlyCost(for: $0) < calculateYearlyCost(for: $1) }
        case .title:
            return expenses.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    // MARK: - Cost Calculation Methods
    
    /// Converts an expense's cost to the currently selected time period.
    private func convertCost(for expense: Expense) -> Double {
        let yearly = calculateYearlyCost(for: expense)
        
        switch selectedPeriod {
        case .yearly:
            return yearly
        case .monthly:
            return yearly / 12
        case .weekly:
            return yearly / 52
        case .daily:
            return yearly / 365
        }
    }
    
    /// Calculates the equivalent yearly cost for a single expense (the baseline for all conversions).
    private func calculateYearlyCost(for expense: Expense) -> Double {
        let frequencyValue = Double(expense.frequencyValue)
        guard frequencyValue > 0 else { return 0 }
        
        switch expense.frequencyUnit {
        case .days: return expense.amount * (365.0 / frequencyValue)
        case .weeks: return expense.amount * (52.0 / frequencyValue)
        case .months: return expense.amount * (12.0 / frequencyValue)
        case .years: return expense.amount / frequencyValue
        }
    }
}
