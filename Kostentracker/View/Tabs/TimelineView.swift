import SwiftUI
import SwiftData

// MARK: - Private types

private struct MonthlyExpenseGroup: Identifiable, Equatable {
    let id: Date
    var month: Date
    var expenses: [Expense]
    var totalAmount: Double
}

// MARK: - View

struct TimelineView: View {

    // MARK: - Properties

    @Environment(UIState.self) private var ui
    @Environment(UserSettings.self) var userSettings
    @Environment(\.modelContext) private var context

    @Query(sort: \Expense.date) private var unfilteredExpenses: [Expense]
    @Query private var categories: [ExpenseCategory]

    private var monthlyGroups: [MonthlyExpenseGroup] {
        let filtered = applyFilters(unfilteredExpenses)
        let onlyActive = Expense.applyCustomFilters(filtered, filter: .active)
        let calendar = Calendar.current

        let groupedByMonth = Dictionary(grouping: onlyActive) { expense in
            calendar.date(from: calendar.dateComponents([.year, .month], from: expense.date))!
        }

        return groupedByMonth.map { (month, expensesInMonth) in
            let total = expensesInMonth.reduce(0.0) { $0 + $1.totalForMonth(containing: month) }
            let sorted = expensesInMonth.sorted { $0.date < $1.date }
            return MonthlyExpenseGroup(id: month, month: month, expenses: sorted, totalAmount: total)
        }
        .sorted { $0.month < $1.month }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Timeline")
                .toolbar { toolbarContent }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var mainContent: some View {
        if monthlyGroups.isEmpty {
            EmptyExpensesView()
        } else {
            expenseList
        }
    }

    private var expenseList: some View {
        let groups = monthlyGroups

        return List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.expenses) { expense in
                        expenseRow(for: expense)
                    }
                } header: {
                    HStack {
                        Text(group.month, format: .dateTime.month(.wide).year())
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(group.totalAmount, format: .currency(code: userSettings.currencyCode))
                            .font(.headline)
                            .fontDesign(.rounded)
                            .foregroundStyle(.primary)
                    }
                    .textCase(nil)
                }
            }
        }
    }

    private func expenseRow(for expense: Expense) -> some View {
        let subtitle = DateFormatter.localizedString(from: expense.date, dateStyle: .medium, timeStyle: .none)

        return ExpenseRow(expense: expense, subtitle: subtitle, tab: .timeline)
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

                Button {
                    markAsPaidOrDelete(expense)
                } label: {
                    switch expense.type {
                    case .oneTime, .inactive: Label("Mark as paid", systemImage: "trash")
                    case .recurring:          Label("Mark as paid", systemImage: "checkmark")
                    }
                }
                .accessibilityLabel("Mark as paid")
                .accessibilityHint("Marks this expense as paid")
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    markAsPaidOrDelete(expense)
                } label: {
                    switch expense.type {
                    case .oneTime, .inactive: Label("Paid", systemImage: "trash")
                    case .recurring:          Label("Paid", systemImage: "checkmark")
                    }
                }
                .tint(expense.type == .recurring ? .green : .red)
                .accessibilityLabel("Mark as paid")
                .accessibilityHint("Marks this expense as paid")
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

// MARK: - Actions & filtering

private extension TimelineView {

    func applyFilters(_ expenses: [Expense]) -> [Expense] {
        let accountFiltered = userSettings.enableAccounts
            ? Expense.applyAccountsFilters(expenses, selectedIDs: ui.selectedAccountIDs)
            : expenses
        return Expense.applyCustomFilters(accountFiltered, filter: ui.selectedFilter)
    }

    func markAsPaidOrDelete(_ expense: Expense) {
        switch expense.type {
        case .oneTime, .inactive:
            context.delete(expense)
            ui.showDeletedPopup(owner: .main)
        case .recurring:
            expense.advanceDueDate()
            ui.showMarkedAsPaidConfirmation(owner: .main)
        }
        try? context.save()
    }
}

// MARK: - Preview

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        TimelineView()
            .environment(UIState())
            .environment(UserSettings())
    }
}
