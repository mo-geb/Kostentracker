//
//  CategoryListView.swift
//  Kostentracker
//

import SwiftUI
import SwiftData

struct ListView: View {
    
    // MARK: - Properties
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Query private var expenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    // User Settings
    @AppStorage(AppSettings.currencyKey) private var currencyCode: String = "EUR"
    
    // State
    @State private var activeSheet: ActiveSheet?
    @State private var showingSettings = false
    @State private var selectedPeriod: CostPeriod = .monthly
    @State private var selectedSort: SortOption = .amountDescending
    @State private var selectedFilter: FilterOption = .nonZero
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Categories")
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
    }
    
    /// A view for a single expense row.
    private func expenseRow(for expense: Expense) -> some View {
        HStack(spacing: 12) {
            if let imageData = expense.customImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
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
        .contentShape(Rectangle())
        .onTapGesture {
            activeSheet = .view(expense)
        }
        .contextMenu {
            Button {
                activeSheet = .edit(expense)
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
                    let new = Expense.createNew(with: context)
                    activeSheet = .new(new)
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
        let filteredExpenses = ExpenseUtils.applyFilters(expenses, filter: selectedFilter)
        // 2. Group all expenses by their category.
        let grouped = Dictionary(grouping: filteredExpenses, by: { $0.category })
        // 3. Map over the categories array to preserve order.
        let processed = categories.compactMap { category -> ProcessedCategory? in
            guard let expenses = grouped[category] else { return nil }
            let total = expenses.reduce(0) { $0 + convertCost(for: $1) }
            let sortedExpenses = sort(expenses: expenses)
            return ProcessedCategory(id: category, category: category, totalCost: total, expenses: sortedExpenses)
        }
        return processed
    }

    /// Sorts an array of expenses based on the `selectedSort` state.
    private func sort(expenses: [Expense]) -> [Expense] {
        switch selectedSort {
        case .amountDescending:
            return expenses.sorted { $0.yearlyCost > $1.yearlyCost }
        case .amountAscending:
            return expenses.sorted { $0.yearlyCost < $1.yearlyCost }
        case .title:
            return expenses.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    /// Converts an expense's cost to the currently selected time period.
    private func convertCost(for expense: Expense) -> Double {
        let yearly = expense.yearlyCost
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
}
