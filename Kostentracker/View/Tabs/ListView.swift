import SwiftUI
import SwiftData

struct ListView: View {
    
    // MARK: - Properties
    // Shared
    @Environment(UIState.self) private var ui
    @Environment(UserSettings.self) var userSettings
    
    // SwiftData
    @Environment(\.modelContext) private var context
    @Query private var unfilteredExpenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    
    // Logic
    @State private var viewModel = ListViewModel()
    
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(navigationTitle)
                .toolbar { toolbarContent }
                .onAppear { updateViewModel() }
                .onChange(of: unfilteredExpenses) { _, _ in updateViewModel() }
                .onChange(of: ui.selectedGroupBy) { _, _ in updateViewModel() }
                .onChange(of: ui.selectedSort) { _, _ in updateViewModel() }
                .onChange(of: ui.selectedFilter) { _, _ in updateViewModel() }
                .onChange(of: ui.selectedAccountIDs) { _, _ in updateViewModel() }
                .onChange(of: ui.selectedDisplayPeriod) { _, _ in updateViewModel() }
                .onChange(of: userSettings.enableAccounts) { _, _ in updateViewModel() }
        }
    }
    
    private func updateViewModel() {
        viewModel.update(from: unfilteredExpenses, ui: ui, userSettings: userSettings)
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
            return String(localized: "Frequency")
        }
    }
    
    /// The main view content, switching between the list and an empty state.
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.processedGroups.isEmpty {
            EmptyExpensesView()
        } else {
            groupList
        }
    }
    
    /// The list of expenses, sectioned by category.
    private var groupList: some View {
        let processedGroups = viewModel.processedGroups
        
        return List {
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
    private func groupHeader(for groupData: ListViewModel.ProcessedGroup) -> some View {
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
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Section: \(groupData.title), \(groupData.expenses.count) expenses")
            Spacer()
            Button(action: {
                if let currentIndex = FrequencyUnit.allCases.firstIndex(of: ui.selectedDisplayPeriod) {
                    let nextIndex = (currentIndex + 1) % FrequencyUnit.allCases.count
                    ui.selectedDisplayPeriod = FrequencyUnit.allCases[nextIndex]
                    HapticManager.selection()
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
        }
        .lineLimit(1)
        .textCase(nil)
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
            switch expense.type {
            case .inactive: subtitle = String(localized: "Inactive")
            case .oneTime, .recurring: subtitle = expense.frequencyUnit.displayText(for: expense.frequencyValue)
                
            }
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
            SharedToolbarElements.AccountsButton()
        }
        
        ToolbarItem() {
            SharedToolbarElements.AddExpenseButton()
        }
    }
}


#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        ListView()
            .environment(UIState())
            .environment(UserSettings())
    }
}
