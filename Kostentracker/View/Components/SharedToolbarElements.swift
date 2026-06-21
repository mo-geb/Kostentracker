import SwiftUI
import SwiftData

enum SharedToolbarElements {
    struct SettingsButton: View {
        @Environment(UIState.self) private var uiState

        var body: some View {
            Button {
                uiState.showSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens app settings and preferences")
            .frame(minWidth: 44, minHeight: 44)
        }
    }
    
    struct AccountsButton: View {
        @Environment(UIState.self) private var ui
        @Environment(UserSettings.self) var userSettings
        @Environment(StoreManager.self) private var store
        @Query(sort: \ExpenseAccount.sortOrder) private var accounts: [ExpenseAccount]

        var body: some View {
            if store.accountsAvailable(in: userSettings) {
                Menu {
                    Toggle(isOn: Binding(
                        get: { ui.getAllAccountsSelected(accounts: accounts) },
                        set: { _ in ui.toggleAllAccounts(accounts: accounts) }
                    )) {
                        Label("All Accounts", systemImage: "person.2.fill")
                    }
                    
                    Divider()
                    
                    ForEach(accounts) { account in
                        Toggle(isOn: Binding(
                            get: { ui.getAccountSelected(account: account) },
                            set: { _ in ui.toggleAccountSelected(for: account) }
                        )) {
                            Label(account.name, systemImage: account.iconName)
                        }
                    }
                } label: {
                    Label("Accounts", systemImage: "person.2")
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
    }
    
    struct OptionsMenu<Content: View>: View {
        private let content: Content
        
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        var body: some View {
            Menu {
                content
            } label: {
                Label("Options", systemImage: "ellipsis")
            }
            .menuActionDismissBehavior(.disabled)
            .accessibilityLabel("Options menu")
            .accessibilityHint("Opens menu with filtering, sorting, and view options")
            .frame(minWidth: 44, minHeight: 44)
        }
    }
    
    struct AddExpenseButton: View {
        @Environment(\.modelContext) private var context
        @Environment(UIState.self) private var uiState
        @Environment(StoreManager.self) private var store
        @Query private var expenses: [Expense]

        var body: some View {
            Button {
                if store.canAddExpense(currentCount: expenses.count) {
                    uiState.createExpense(from: ExpenseDraft.createNew(with: context))
                } else {
                    uiState.presentPaywall()
                }
            } label: {
                Label("Add Expense", systemImage: "plus")
            }
            .accessibilityLabel("Add Expense")
            .accessibilityHint("Creates a new expense entry")
            .frame(minWidth: 44, minHeight: 44)
        }
    }
    
    struct DismissButton: View {
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            Button {
                dismiss()
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
            .accessibilityLabel("Cancel")
            .accessibilityHint("Closes this screen without saving changes")
            .frame(minWidth: 44, minHeight: 44)
        }
    }
    
    // MARK: - Option Button Elements
    
    struct FilterPicker: View {
        @Environment(UIState.self) private var uiState

        var body: some View {
            @Bindable var ui = uiState
            
            Picker(selection: $ui.selectedFilter) {
                ForEach(FilterOption.allCases) { option in
                    Button {} label: {
                        Text(option.localizedName)
                        Text(option.localizedDescription)
                    }
                    .tag(option)
                }
            } label: {
                Label("Filter By", systemImage: "line.3.horizontal.decrease.circle")
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Filter expenses")
            .accessibilityHint("Choose which expenses to display")
        }
    }
    
    struct SortPicker: View {
        @Environment(UIState.self) private var uiState

        var body: some View {
            @Bindable var ui = uiState

            Picker(selection: $ui.selectedSort, label: Label("Sort By", systemImage: "arrow.up.arrow.down")) {
                ForEach(SortOption.allCases) { option in
                    Button {} label: {
                        Text(option.localizedName)
                        Text(option.localizedDescription)
                    }
                    .tag(option)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Sort expenses")
            .accessibilityHint("Choose how to order the expense list")
        }
    }
    
    struct GroupByPicker: View {
        @Environment(UIState.self) private var uiState

        var body: some View {
            @Bindable var ui = uiState

            Picker(selection: $ui.selectedGroupBy, label: Label("Group By", systemImage: "rectangle.3.group")) {
                ForEach(GroupByOption.allCases) { option in
                    Text(option.localizedName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Group expenses")
            .accessibilityHint("Choose how to organize expenses into sections")
        }
    }
    
    struct ViewModePicker: View {
        @Environment(UIState.self) private var uiState

        var body: some View {
            @Bindable var ui = uiState

            Picker("View Mode", selection: $ui.selectedViewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Label(mode.localizedName, systemImage: mode.iconName).tag(mode)
                }
            }
            .pickerStyle(.palette)
            .accessibilityLabel("View Mode")
            .accessibilityHint("Switch between different display modes")
        }
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        Color.clear
            .navigationTitle("Preview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SharedToolbarElements.AccountsButton()
                }
            }
    }
    .environment(UIState())
    .environment(UserSettings())
}
