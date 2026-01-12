import SwiftUI
import SwiftData

struct ListView: View {
    
    // MARK: - Properties
    // Shared
    @EnvironmentObject var ui: UIState
    @EnvironmentObject var userSettings: UserSettings
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Query private var expenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(navigationTitle)
                .toolbar { toolbarContent }
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
        case .frequency:
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
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Section: \(groupData.title)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Expenses list with \(processedGroups.count) sections")
    }
    
    /// The header for each category section, showing the name and total cost.
    private func groupHeader(for groupData: ProcessedGroup) -> some View {
        HStack {
            switch ui.selectedGroupBy {
            case .categories:
                if let firstExpense = groupData.expenses.first {
                    Image(systemName: firstExpense.categoryIconName)
                        .foregroundStyle(firstExpense.categoryColor)
                        .imageScale(.small)
                        .accessibilityLabel("\(groupData.title) category icon")
                } else {
                    Image(systemName: "tray")
                        .imageScale(.small)
                        .accessibilityLabel("Default category icon")
                }
            case .frequency:
                Image(systemName: "clock")
                    .foregroundStyle(.blue)
                    .imageScale(.small)
                    .accessibilityLabel("Frequency icon")
            case .none:
                Image(systemName: "list.bullet")
                    .foregroundStyle(.gray)
                    .imageScale(.small)
                    .accessibilityLabel("List icon")
            }
            
            Text(groupData.title)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Section: \(groupData.title), \(groupData.expenses.count) expenses")
            Spacer()
            Button(action: {
                if let currentIndex = FrequencyUnit.allCases.firstIndex(of: ui.selectedDisplayPeriod) {
                    let nextIndex = (currentIndex + 1) % FrequencyUnit.allCases.count
                    ui.selectedDisplayPeriod = FrequencyUnit.allCases[nextIndex]
                }
            }) {
                HStack(spacing: 8) {
                    Text(ui.selectedDisplayPeriod.periodName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .lineLimit(1)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                        )
                    Text(groupData.totalCost, format: .currency(code: userSettings.currencyCode))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .contentShape(Rectangle())
                .fixedSize(horizontal: true, vertical: false)
            }
            .buttonStyle(.plain)
            .layoutPriority(1)
            .accessibilityLabel("Change display period from \(ui.selectedDisplayPeriod.periodName). Total: \(groupData.totalCost, format: .currency(code: userSettings.currencyCode))")
            .accessibilityHint("Double tap to cycle through yearly, monthly, weekly, and daily periods")
            .accessibilityValue("\(ui.selectedDisplayPeriod.periodName)")
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Section header: \(groupData.title) with \(groupData.expenses.count) expenses, total \(groupData.totalCost, format: .currency(code: userSettings.currencyCode)) per \(ui.selectedDisplayPeriod.periodName)")
    }
    
    /// A view for a single expense row.
    private func expenseRow(for expense: Expense) -> some View {
        let subtitle: String
        switch ui.selectedGroupBy {
        case .frequency:
            subtitle = expense.categoryName
        case .categories, .none:
            subtitle = expense.frequencyUnit.displayText(for: expense.frequencyValue)
        }
        
        return ExpenseRow(expense: expense, subtitle: subtitle, tab: .list)
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
        let filteredExpenses = Expense.applyCustomFilters(expenses, filter: ui.selectedFilter)
        let grouped: [String: [Expense]]
        
        switch ui.selectedGroupBy {
        case .none:
            grouped = ["all": filteredExpenses]
        case .categories:
            grouped = Dictionary(grouping: filteredExpenses, by: { $0.categoryName })
        case .frequency:
            grouped = Dictionary(grouping: filteredExpenses, by: { $0.frequencyUnit.rawValue.capitalized })
        }
        
        let processed = grouped.map { (key, expenses) -> ProcessedGroup in
            let total = expenses.reduce(0) { $0 + $1.getCostFor(for: ui.selectedDisplayPeriod) }
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
        case .frequency:
            return groups.sorted {
                guard
                    let unitA = FrequencyUnit(rawValue: $0.title.lowercased()),
                    let unitB = FrequencyUnit(rawValue: $1.title.lowercased())
                else { return false }
                return unitA.sortOrder < unitB.sortOrder
            }
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
        #endif
        
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
