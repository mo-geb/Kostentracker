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
    @AppStorage(UserSettings.currencyKey) private var currencyCode: String = "EUR"
    
    // State
    @State private var activeSheet: ActiveExpenseSheet?
    @State private var showingSettings = false
    @State private var selectedPeriod: CostPeriod = .monthly
    @State private var selectedSort: SortOption = .amountDescending
    @State private var selectedFilter: FilterOption = .nonZero
    @State private var selectedGroupBy: GroupByOption = .categories
    @State private var selectedViewMode: ViewMode = .normal
    
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
            return String(localized: "All Expenses")
        case .categories:
            return String(localized: "Categories")
        case .frequencyUnit:
            return String(localized: "Frequency Units")
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
            groupList
        }
    }
    
    /// The list of expenses, sectioned by category.
    private var groupList: some View {
        List {
            ForEach(processedGroups) { groupData in
                Section {
                    ForEach(groupData.expenses) { expense in
                        expenseRow(for: expense)
                    }
                } header: {
                    groupHeader(for: groupData)
                }
            }
        }
    }
    
    /// The header for each category section, showing the name and total cost.
    private func groupHeader(for groupData: ProcessedGroup) -> some View {
        HStack {
            switch selectedGroupBy {
            case .categories:
                if let firstExpense = groupData.expenses.first {
                    Image(systemName: firstExpense.categoryIconName)
                        .foregroundStyle(firstExpense.categoryColor)
                } else {
                    Image(systemName: "tray")
                }
            case .frequencyUnit:
                Image(systemName: "clock")
                    .foregroundStyle(.blue)
            case .none:
                Image(systemName: "list.bullet")
                    .foregroundStyle(.gray)
            }
            
            Text(groupData.title)
            Spacer()
            Button(action: {
                if let currentIndex = CostPeriod.allCases.firstIndex(of: selectedPeriod) {
                    let nextIndex = (currentIndex + 1) % CostPeriod.allCases.count
                    selectedPeriod = CostPeriod.allCases[nextIndex]
                }
            }) {
                HStack(spacing: 8) {
                    Text(selectedPeriod.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                        )
                    Text(groupData.totalCost, format: .currency(code: currencyCode))
                        .font(.headline)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change display period")
            .accessibilityHint("Cycles through yearly, monthly, weekly, daily")
        }
    }
    
    /// A view for a single expense row.
    private func expenseRow(for expense: Expense) -> some View {
        let subtitle: String
        switch selectedGroupBy {
        case .frequencyUnit:
            subtitle = expense.categoryName
        case .categories, .none:
            subtitle = expense.frequencyUnit.displayText(for: expense.frequencyValue)
        }
        
        @ViewBuilder
        var rowContent: some View {
            switch selectedViewMode {
            case .compact:
                expense.createCompactRow(convertedAmount: convertCost(for: expense), currencyCode: currencyCode)
            case .normal:
                expense.createNormalRow( subtitle: subtitle, convertedAmount: convertCost(for: expense), currencyCode: currencyCode)
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
                // Removed Display Period Picker
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
                
                Picker(selection: $selectedViewMode, label: Label("View Mode", systemImage: "list.bullet.rectangle")) {
                    ForEach(ViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
            } label: {
                Label("Options", systemImage: "ellipsis")
            }
        }
        
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed)
        }
        
        ToolbarItem() {
            Button {
                activeSheet = .new(ExpenseDraft.createNew(with: context))
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
        let filteredExpenses = Utils.applyFilters(expenses, filter: selectedFilter)
        let grouped: [String: [Expense]]
        
        switch selectedGroupBy {
        case .none:
            grouped = ["all": filteredExpenses]
        case .categories:
            grouped = Dictionary(grouping: filteredExpenses, by: { $0.categoryName })
        case .frequencyUnit:
            grouped = Dictionary(grouping: filteredExpenses, by: { $0.frequencyUnit.rawValue.capitalized })
        }
        
        let processed = grouped.map { (key, expenses) -> ProcessedGroup in
            let total = expenses.reduce(0) { $0 + convertCost(for: $1) }
            let sortedExpenses = sortExpenses(expenses: expenses)
            let title = selectedGroupBy == .none ? String(localized: "All Expenses") : key
            return ProcessedGroup(id: key, title: title, totalCost: total, expenses: sortedExpenses)
        }
        
        return sortGroups(groups: processed)
    }

    /// Sorts an array of expenses based on the `selectedSort` state.
    private func sortExpenses(expenses: [Expense]) -> [Expense] {
        switch selectedSort {
        case .amountDescending:
            return expenses.sorted { $0.yearlyCost > $1.yearlyCost }
        case .amountAscending:
            return expenses.sorted { $0.yearlyCost < $1.yearlyCost }
        case .title:
            return expenses.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
    
    /// Sorts an array of groups based on the `selectedGroupBy` state.
    private func sortGroups(groups: [ProcessedGroup]) -> [ProcessedGroup] {
        switch selectedGroupBy {
        case .none:
            return groups
        case .categories:
            return groups.sorted {
                guard
                    let firstA = $0.expenses.first,
                    let firstB = $1.expenses.first
                else { return false }
                return firstA.categorySortOrder < firstB.categorySortOrder
            }
        case .frequencyUnit:
            return groups.sorted {
                guard
                    let unitA = FrequencyUnit(rawValue: $0.title.lowercased()),
                    let unitB = FrequencyUnit(rawValue: $1.title.lowercased())
                else { return false }
                return unitA.sortOrder < unitB.sortOrder
            }
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
