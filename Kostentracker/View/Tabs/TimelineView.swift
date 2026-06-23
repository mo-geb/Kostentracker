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

    @Environment(UIState.self) private var ui
    @Environment(UserSettings.self) var userSettings
    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var context

    @Query(sort: \Expense.date) private var unfilteredExpenses: [Expense]
    @State private var detailRoute: ExpenseDetailRoute?

    private var monthlyGroups: [MonthlyExpenseGroup] {
        let filtered = Expense.applyFilters(unfilteredExpenses, ui: ui, userSettings: userSettings, store: store)
        let onlyActive = Expense.applyCustomFilters(filtered, filter: .active)
        let calendar = Calendar.current

        return Dictionary(grouping: onlyActive) { expense in
            calendar.date(from: calendar.dateComponents([.year, .month], from: expense.date))!
        }
        .map { month, expensesInMonth in
            let total = expensesInMonth.reduce(0.0) { $0 + $1.totalForMonth(containing: month) }
            let sorted = expensesInMonth.sorted { $0.date < $1.date }
            return MonthlyExpenseGroup(id: month, month: month, expenses: sorted, totalAmount: total)
        }
        .sorted { $0.month < $1.month }
    }

    // MARK: - Body

    var body: some View {
        let groups = monthlyGroups
        return NavigationStack {
            List {
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
            .overlay { if groups.isEmpty { EmptyExpensesView() } }
            .navigationTitle("Timeline")
            .toolbar { toolbarContent }
            .expenseDetailDestination($detailRoute)
        }
    }

    // MARK: - Row

    private func expenseRow(for expense: Expense) -> some View {
        Button { detailRoute = ExpenseDetailRoute(expense: expense) } label: {
            ExpenseRow(expense: expense, subtitle: expense.date.formatted(date: .abbreviated, time: .omitted), tab: .timeline)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
                Button {
                    detailRoute = ExpenseDetailRoute(expense: expense, startInEdit: true)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    markAsPaid(expense)
                } label: {
                    Label("Mark as paid", systemImage: "checkmark")
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button { markAsPaid(expense) } label: {
                    Label("Paid", systemImage: "checkmark")
                }
                .tint(.green)
            }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            SharedToolbarElements.SettingsButton()
        }
        ToolbarItem {
            SharedToolbarElements.OptionsMenu {
                SharedToolbarElements.ViewModePicker()
            }
        }
        ToolbarItem { SharedToolbarElements.AccountsButton() }
        ToolbarItem { SharedToolbarElements.AddExpenseButton() }
    }
}

// MARK: - Actions

private extension TimelineView {
    func markAsPaid(_ expense: Expense) {
        switch expense.type {
        case .oneTime, .inactive: expense.date = .distantPast
        case .recurring:          expense.advanceDueDate()
        }
        ui.showMarkedAsPaidConfirmation(owner: .main)
        try? context.save()
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    TimelineView()
}
