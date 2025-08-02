import SwiftUI
import SwiftData

struct ListView: View {
    
    // MARK: - Properties
    // Shared
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var ui: UIState
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Query private var expenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    // State
    @State private var selectedPeriod: CostPeriod = .monthly
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(navigationTitle)
                .toolbar { toolbarContent }
                .sheet(item: $ui.activeExpenseSheet) { sheet in
                    SharedSheets.expenseHandlingSheet(sheet)
                }
                .sheet(isPresented: $ui.showingSettings) {
                    SharedSheets.settingsSheet
                }
        }
    }
    
    // MARK: - View Components
    
    /// Returns the dynamic navigation title based on the selected grouping option.
    private var navigationTitle: String {
        switch ui.selectedGroupBy {
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
            EmptyExpensesView()
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
            switch ui.selectedGroupBy {
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
                    Text(groupData.totalCost, format: .currency(code: userSettings.currencyCode))
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
        switch ui.selectedGroupBy {
        case .frequencyUnit:
            subtitle = expense.categoryName
        case .categories, .none:
            subtitle = expense.frequencyUnit.displayText(for: expense.frequencyValue)
        }
        
        @ViewBuilder
        var rowContent: some View {
            switch ui.selectedViewMode {
            case .compact:
                expense.createCompactRow(convertedAmount: convertCost(for: expense), currencyCode: userSettings.currencyCode)
            case .normal:
                expense.createNormalRow( subtitle: subtitle, convertedAmount: convertCost(for: expense), currencyCode: userSettings.currencyCode)
            }
        }
        
        return rowContent
            .contentShape(Rectangle())
            .onTapGesture { ui.activeExpenseSheet = .view(expense) }
            .contextMenu {
                Button {
                    ui.activeExpenseSheet = .edit(expense)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
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
                SharedToolbarElements.SortPicker()
                SharedToolbarElements.GroupByPicker()
                SharedToolbarElements.ViewModePicker()
            }
        }
        
        ToolbarItem() {
            SharedToolbarElements.AddExpenseButton()
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
        let filteredExpenses = Expense.applyFilters(expenses, filter: ui.selectedFilter)
        let grouped: [String: [Expense]]
        
        switch ui.selectedGroupBy {
        case .none:
            grouped = ["all": filteredExpenses]
        case .categories:
            grouped = Dictionary(grouping: filteredExpenses, by: { $0.categoryName })
        case .frequencyUnit:
            grouped = Dictionary(grouping: filteredExpenses, by: { $0.frequencyUnit.rawValue.capitalized })
        }
        
        let processed = grouped.map { (key, expenses) -> ProcessedGroup in
            let total = expenses.reduce(0) { $0 + convertCost(for: $1) }
            let sortedExpenses = Expense.sortExpenses(expenses: expenses, sortOption: ui.selectedSort)
            let title = ui.selectedGroupBy == .none ? String(localized: "All Expenses") : key
            return ProcessedGroup(id: key, title: title, totalCost: total, expenses: sortedExpenses)
        }
        
        return sortGroups(groups: processed)
    }
    
    /// Sorts an array of groups based on the `selectedGroupBy` state.
    private func sortGroups(groups: [ProcessedGroup]) -> [ProcessedGroup] {
        switch ui.selectedGroupBy {
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
            ListView()
                .modelContainer(container)
                .environmentObject(UIState())
                .environmentObject(UserSettings())
        }
        
    } catch {
        return Text("Failed to create preview container: \(error.localizedDescription)")
    }
}
