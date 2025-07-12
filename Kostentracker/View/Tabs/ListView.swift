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
    @State private var selectedGroupBy: GroupByOption = .categories
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(navigationTitle)
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
    
    /// Returns the dynamic navigation title based on the selected grouping option.
    private var navigationTitle: String {
        switch selectedGroupBy {
        case .none:
            return "All Expenses"
        case .categories:
            return "Categories"
        case .frequencyUnit:
            return "Frequency Units"
        }
    }
    
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
            ForEach(processedGroups) { groupData in
                Section {
                    ForEach(groupData.expenses) { expense in
                        expenseRow(for: expense)
                    }
                } header: {
                    categoryHeader(for: groupData)
                }
            }
        }
    }
    
    /// The header for each category section, showing the name and total cost.
    private func categoryHeader(for groupData: ProcessedGroup) -> some View {
        HStack {
            // Show appropriate icon based on grouping
            if selectedGroupBy == .categories {
                // For categories, we need to find the category to get its icon
                if let firstExpense = groupData.expenses.first {
                    Image(systemName: firstExpense.category.iconName)
                        .foregroundStyle(firstExpense.category.color)
                } else {
                    Image(systemName: "tray")
                }
            } else if selectedGroupBy == .frequencyUnit {
                // For frequency units, show a clock icon
                Image(systemName: "clock")
                    .foregroundStyle(.blue)
            } else {
                // For "none" grouping, show a list icon
                Image(systemName: "list.bullet")
                    .foregroundStyle(.gray)
            }
            
            Text(groupData.title)
            Spacer()
            Text(groupData.totalCost, format: .currency(code: currencyCode))
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
        .padding(.vertical, 4)
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
                    
                    Picker(selection: $selectedGroupBy, label: Label("Group By", systemImage: "rectangle.3.group")) {
                        ForEach(GroupByOption.allCases) { option in
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
    
    /// A struct to hold the processed data for each group.
    private struct ProcessedGroup: Identifiable {
        let id: String
        var title: String
        var totalCost: Double
        var expenses: [Expense]
    }
    
    /// This is the core logic. It groups, sorts, and calculates costs based on user selections.
    private var processedGroups: [ProcessedGroup] {
        // 1. Apply filters to expenses
        let filteredExpenses = ExpenseUtils.applyFilters(expenses, filter: selectedFilter)
        
        // 2. Group expenses based on selected grouping option
        let grouped: [String: [Expense]]
        
        switch selectedGroupBy {
        case .none:
            // Single group with all expenses
            grouped = ["all": filteredExpenses]
        case .categories:
            // Group by category
            grouped = Dictionary(grouping: filteredExpenses, by: { $0.category.name })
        case .frequencyUnit:
            // Group by frequency unit
            grouped = Dictionary(grouping: filteredExpenses, by: { $0.frequencyUnit.rawValue.capitalized })
        }
        
        // 3. Convert to ProcessedGroup array
        let processed = grouped.map { (key, expenses) -> ProcessedGroup in
            let total = expenses.reduce(0) { $0 + convertCost(for: $1) }
            let sortedExpenses = sort(expenses: expenses)
            let title = selectedGroupBy == .none ? "All Expenses" : key
            return ProcessedGroup(id: key, title: title, totalCost: total, expenses: sortedExpenses)
        }
        
        // 4. Sort groups by total cost (descending)
        return processed.sorted { $0.totalCost > $1.totalCost }
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
