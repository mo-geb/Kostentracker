import SwiftUI
import SwiftData

struct TimelineView: View {
    // MARK: - Properties
    // Shared
    @Environment(UIState.self) private var ui
    @Environment(UserSettings.self) var userSettings
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date) private var unfilteredExpenses: [Expense]
    @Query private var categories: [ExpenseCategory]
    
    // State
    @State private var viewModel = TimelineViewModel()

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Timeline")
                .toolbar { toolbarContent }
                .onAppear { updateViewModel() }
                .onChange(of: unfilteredExpenses) { _, _ in updateViewModel() }
                .onChange(of: ui.selectedFilter) { _, _ in updateViewModel() }
                .onChange(of: ui.selectedAccountIDs) { _, _ in updateViewModel() }
                .onChange(of: userSettings.enableAccounts) { _, _ in updateViewModel() }
        }
    }
    
    private func updateViewModel() {
        viewModel.update(from: unfilteredExpenses, ui: ui, userSettings: userSettings)
    }
    
    // MARK: - View Components
    
    /// The main content of the view, showing a message if there are no expenses,
    /// or the list of expenses grouped by month.
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.monthlyGroups.isEmpty {
            EmptyExpensesView()
        } else {
            expenseList
        }
    }
    
    /// The list that displays expenses, grouped into sections by month.
    private var expenseList: some View {
        let monthlyGroups = viewModel.monthlyGroups
        
        return List {
            ForEach(monthlyGroups) { group in
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
    
    /// A view representing a single row in the expense list.
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
                    viewModel.markAsPaidOrDelete(expense, context: context, ui: ui)
                } label: {
                    switch expense.type {
                    case .oneTime, .inactive:
                        Label("Mark as paid", systemImage: "trash")
                    case .recurring:
                        Label("Mark as paid", systemImage: "checkmark")
                    }
                }
                .accessibilityLabel("Mark as paid")
                .accessibilityHint("Marks this expense as paid")
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    viewModel.markAsPaidOrDelete(expense, context: context, ui: ui)
                } label: {
                    switch expense.type {
                    case .oneTime, .inactive:
                        Label("Paid", systemImage: "trash")
                    case .recurring:
                        Label("Paid", systemImage: "checkmark")
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

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        TimelineView()
            .environment(UIState())
            .environment(UserSettings())
    }
}
