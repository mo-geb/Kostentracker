import SwiftUI
import SwiftData

// MARK: - Private types

private struct ProcessedGroup: Identifiable, Equatable {
    let id: String
    var title: String
    var totalCost: Double
    var expenses: [Expense]
}

// MARK: - View

struct ListView: View {

    // MARK: - Properties

    @Environment(UIState.self) private var ui
    @Environment(UserSettings.self) var userSettings
    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var context

    @Query(sort: [
        SortDescriptor(\Expense.amount, order: .reverse),
        SortDescriptor(\Expense.date),
        SortDescriptor(\Expense.frequencyValue)
    ]) private var unfilteredExpenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var detailRoute: ExpenseDetailRoute?

    private var processedGroups: [ProcessedGroup] {
        let filtered = Expense.applyFilters(unfilteredExpenses, ui: ui, userSettings: userSettings, store: store)
        let grouped: [String: [Expense]]

        switch ui.selectedGroupBy {
        case .none:
            grouped = ["all": filtered]
        case .categories:
            grouped = Dictionary(grouping: filtered, by: { $0.categoryName })
        }

        let processed = grouped.map { (key, expenses) -> ProcessedGroup in
            let total = expenses.reduce(0) { $0 + $1.getCostFor(for: ui.selectedDisplayPeriod) }
            let sorted = Expense.sortExpenses(expenses: expenses, sortOption: ui.selectedSort)
            let title = ui.selectedGroupBy == .none ? String(localized: "All Expenses") : key
            return ProcessedGroup(id: key, title: title, totalCost: total, expenses: sorted)
        }

        return sortGroups(processed)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(navigationTitle)
                .toolbar { toolbarContent }
                .expenseDetailDestination($detailRoute)
        }
    }

    // MARK: - View Components

    private var navigationTitle: String {
        switch ui.selectedGroupBy {
        case .none:       return String(localized: "All Expenses")
        case .categories: return String(localized: "Categories")
        }
    }

    private var mainContent: some View {
        groupList
            .overlay {
                if processedGroups.isEmpty { EmptyExpensesView() }
            }
    }

    private var groupList: some View {
        let groups = processedGroups

        return List {
            ForEach(groups) { groupData in
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
            case .none:
                Image(systemName: "list.bullet")
                    .foregroundStyle(.gray)
                    .imageScale(.small)
                    .accessibilityLabel("List icon")
            }

            Text(groupData.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Section: \(groupData.title), \(groupData.expenses.count) expenses")
            Spacer()
            Button(action: {
                ui.selectedDisplayPeriod.cycleToNext()
            }) {
                HStack(spacing: 8) {
                    Text(ui.selectedDisplayPeriod.periodName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .lineLimit(1)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                    Text(groupData.totalCost, format: .currency(code: userSettings.currencyCode))
                        .fontDesign(.rounded)
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
            .sensoryFeedback(.selection, trigger: ui.selectedDisplayPeriod)
        }
        .lineLimit(1)
        .textCase(nil)
    }

    private func expenseRow(for expense: Expense) -> some View {
        let subtitle: String
        switch expense.type {
        case .inactive:            subtitle = String(localized: "Inactive")
        case .oneTime, .recurring: subtitle = expense.frequencyUnit.displayText(for: expense.frequencyValue)
        }

        return ExpenseRow(expense: expense, subtitle: subtitle, tab: .list)
            .contentShape(Rectangle())
            .onTapGesture { detailRoute = ExpenseDetailRoute(expense: expense) }
            .contextMenu {
                Button {
                    detailRoute = ExpenseDetailRoute(expense: expense, startInEdit: true)
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
            SharedToolbarElements.AccountsButton()
        }
        ToolbarItem() {
            SharedToolbarElements.AddExpenseButton()
        }
    }
}

// MARK: - Data transformation

private extension ListView {

    func sortGroups(_ groups: [ProcessedGroup]) -> [ProcessedGroup] {
        switch ui.selectedGroupBy {
        case .none:
            return groups
        case .categories:
            return groups.sorted {
                guard let a = $0.expenses.first, let b = $1.expenses.first else { return false }
                return a.categorySortOrder < b.categorySortOrder
            }
        }
    }
}

// MARK: - Preview

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        ListView()
            .environment(UIState())
            .environment(UserSettings())
            .environment(StoreManager())
    }
}
