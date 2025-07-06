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
    @Query private var categories: [ExpenseCategory]
    
    @AppStorage(AppSettings.currencyKey) private var currencyCode: String = "EUR"
    
    // MARK: - State for User Controls
    
    @State private var showingSettings = false
    @State private var selectedExpense: Expense?
    @State private var newExpense: Expense?
    @State private var selectedPeriod: CostPeriod = .monthly
    @State private var selectedSort: SortOption = .dateDescending
    @State private var selectedFilter: FilterOption = .all
    
    @State var searchText = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Categories")
                .toolbar { toolbarContent }
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
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
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
            Text(categoryData.category.name)
            Spacer()
            Text(categoryData.totalCost, format: .currency(code: currencyCode))
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
    
    /// A view for a single expense row.
    private func expenseRow(for expense: Expense) -> some View {
        HStack(spacing: 12) {
            if let imageData = expense.customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Fallback to the category icon - keep as circle
                ZStack {
                    Circle()
                        .fill(expense.category.color.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: expense.category.iconName)
                        .font(.title2)
                        .foregroundStyle(expense.category.color)
                }
            }
            
            VStack(alignment: .leading) {
                Text(expense.title)
                    .font(.headline)
                Text(FrequencyUnit.formatFrequency(value: expense.frequencyValue, unit: expense.frequencyUnit))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(convertCost(for: expense), format: .currency(code: currencyCode))
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedExpense = expense
        }
        .contextMenu {
            Button {
                selectedExpense = expense
            } label: {
                Label("Edit", systemImage: "pencil")
            }
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
                    
                    Picker(selection: $selectedFilter, label: Label("Filter By", systemImage: "line.3.horizontal.decrease.circle")) {
                        ForEach(FilterOption.allCases) { option in
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
                    newExpense = Expense.createNew(with: context)
                } label: {
                    Label("Add Expense", systemImage: "plus")
                }
            }
    }
    
    // MARK: - Data Processing
    
    /// A struct to hold the processed data for each category.
    private struct ProcessedCategory: Identifiable {
        let id: ExpenseCategory
        var category: ExpenseCategory
        var totalCost: Double
        var expenses: [Expense]
    }
    
    /// This is the core logic. It groups, sorts, and calculates costs based on user selections.
    private var processedCategories: [ProcessedCategory] {
        // 1. Apply filters to expenses
        let filteredExpenses = applyFilters(to: expenses)
        
        // 2. Group all expenses by their category.
        let grouped = Dictionary(grouping: filteredExpenses, by: { $0.category })
        
        // 3. Map over the grouped dictionary to process each category.
        let processed = grouped.map { (category, expenses) -> ProcessedCategory in
            // a. Calculate the total cost for this category based on the selected period.
            let total = expenses.reduce(0) { $0 + convertCost(for: $1) }
            
            // b. Sort the expenses within this category based on the selected sort option.
            let sortedExpenses = sort(expenses: expenses)
            
            return ProcessedCategory(id: category, category: category, totalCost: total, expenses: sortedExpenses)
        }
        
        // 4. Sort the categories themselves alphabetically.
        return processed.sorted { $0.category.name < $1.category.name }
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

    // MARK: - Helper Methods
    
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
        case .day: return expense.amount * (365.0 / frequencyValue)
        case .week: return expense.amount * (52.0 / frequencyValue)
        case .month: return expense.amount * (12.0 / frequencyValue)
        case .year: return expense.amount / frequencyValue
        }
    }
    
    /// Applies all active filters to the expenses array.
    private func applyFilters(to expenses: [Expense]) -> [Expense] {
        var filtered = expenses
        
        switch selectedFilter {
        case .all:
            // No filtering needed
            break
        case .nonZero:
            // Filter out zero cost expenses
            filtered = filtered.filter { expense in
                let yearlyCost = calculateYearlyCost(for: expense)
                return yearlyCost > 0
            }
        case .recent:
            // Filter to show only expenses from the last 30 days
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            filtered = filtered.filter { expense in
                return expense.date >= thirtyDaysAgo
            }
        }
        
        return filtered
    }


}
