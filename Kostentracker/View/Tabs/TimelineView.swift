import SwiftUI
import SwiftData

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
        let projectFuture = ui.timelineOccurrenceDisplay == .allUpcoming

        let occurrences = onlyActive.flatMap {
            Self.occurrences(for: $0, calendar: calendar, projectFuture: projectFuture)
        }

        return Dictionary(grouping: occurrences, by: \.month)
            .map { month, occurrencesInMonth in
                let total = occurrencesInMonth.reduce(0.0) { $0 + $1.amount }
                let sorted = occurrencesInMonth.sorted { $0.occurrenceDate < $1.occurrenceDate }
                return MonthlyExpenseGroup(id: month, month: month, occurrences: sorted, totalAmount: total)
            }
            .sorted { $0.month < $1.month }
    }

    /// Expands an expense into timeline rows. In "next due only" mode (or for
    /// one-time expenses) it yields a single collapsed row at the due date. In
    /// "all upcoming" mode it yields one row per occurrence through the horizon.
    private static func occurrences(for expense: Expense, calendar: Calendar, projectFuture: Bool) -> [TimelineOccurrence] {
        let dueMonth = calendar.startOfMonth(for: expense.date)

        guard projectFuture, expense.type == .recurring, expense.frequencyValue > 0 else {
            return [TimelineOccurrence(
                expense: expense,
                month: dueMonth,
                occurrenceDate: expense.date,
                amount: expense.totalForMonth(containing: dueMonth),
                isCurrentDue: true,
                showsMonthlyTotal: true
            )]
        }

        let horizon = calendar.date(byAdding: .month, value: timelineProjectionMonths,
                                    to: calendar.startOfMonth(for: Date())) ?? dueMonth
        return expense.occurrenceDates(through: horizon, calendar: calendar).map { date in
            TimelineOccurrence(
                expense: expense,
                month: calendar.startOfMonth(for: date),
                occurrenceDate: date,
                amount: expense.amount,
                isCurrentDue: date == expense.date,
                showsMonthlyTotal: false
            )
        }
    }

    // MARK: - Body

    var body: some View {
        let groups = monthlyGroups
        return NavigationStack {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.occurrences) { occurrence in
                            expenseRow(for: occurrence)
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

    private func expenseRow(for occurrence: TimelineOccurrence) -> some View {
        let expense = occurrence.expense
        return Button { detailRoute = ExpenseDetailRoute(expense: expense) } label: {
            ExpenseRow(
                expense: expense,
                subtitle: occurrence.occurrenceDate.formatted(date: .abbreviated, time: .omitted),
                tab: .timeline,
                occurrenceDate: occurrence.occurrenceDate,
                isUpcoming: !occurrence.isCurrentDue,
                showsMonthlyTotal: occurrence.showsMonthlyTotal
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
                Button {
                    detailRoute = ExpenseDetailRoute(expense: expense, startInEdit: true)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                // Only the next-due occurrence is payable; future previews are not.
                if occurrence.isCurrentDue {
                    Button {
                        markAsPaid(expense)
                    } label: {
                        Label("Mark as paid", systemImage: "checkmark")
                    }
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if occurrence.isCurrentDue {
                    Button { markAsPaid(expense) } label: {
                        Label("Paid", systemImage: "checkmark")
                    }
                    .tint(.green)
                }
            }
    }

    // MARK: - Toolbar

    private var occurrenceDisplayPicker: some View {
        @Bindable var ui = ui
        return Picker(selection: $ui.timelineOccurrenceDisplay,
                      label: Label("Show", systemImage: "calendar.badge.clock")) {
            ForEach(TimelineOccurrenceDisplay.allCases) { option in
                Text(option.localizedName).tag(option)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Show")
        .accessibilityHint("Choose whether to show only the next due charge or every occurrence")
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            SharedToolbarElements.SettingsButton()
        }
        ToolbarItem {
            SharedToolbarElements.OptionsMenu {
                occurrenceDisplayPicker
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
        withAnimation {
            switch expense.type {
            case .oneTime, .inactive: expense.date = .distantPast
            case .recurring:          expense.advanceDueDate()
            }
            try? context.save()
        }
        ui.showMarkedAsPaidConfirmation(owner: .main)
    }
}

// MARK: - Private types

private struct TimelineOccurrence: Identifiable {
    let expense: Expense
    let month: Date          // first day of the month bucket (section)
    let occurrenceDate: Date // this occurrence's date
    let amount: Double        // amount contributed to the month's section total
    let isCurrentDue: Bool    // the next due occurrence → markable / payable
    let showsMonthlyTotal: Bool // collapsed next-due row shows the "total this month" line

    var id: String { "\(expense.persistentModelID)-\(occurrenceDate.timeIntervalSinceReferenceDate)" }
}

private struct MonthlyExpenseGroup: Identifiable {
    let id: Date
    var month: Date
    var occurrences: [TimelineOccurrence]
    var totalAmount: Double
}

private let timelineProjectionMonths = 12

#Preview(traits: .modifier(PreviewModelContainer())) {
    TimelineView()
}
