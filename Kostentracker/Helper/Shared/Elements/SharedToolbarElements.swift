import SwiftUI
import SwiftData

enum SharedToolbarElements {
    struct SettingsButton: View {
        @EnvironmentObject var ui: UIState
        
        var body: some View {
            Button {
                ui.showSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens app settings and preferences")
            .frame(minWidth: 44, minHeight: 44)
        }
    }
    
    struct AccountsButton: View {
        @EnvironmentObject var ui: UIState
        @EnvironmentObject var userSettings: UserSettings
        @Query(sort: \ExpenseAccount.sortOrder) private var accounts: [ExpenseAccount]
        
        var body: some View {
            if userSettings.enableAccounts {
                Menu {
                    Section("Accounts") {
                        Button {
                            ui.toggleAllAccounts(accounts: accounts)
                        } label: {
                            let isAllSelected = ui.getAllAccountsSelected(accounts: accounts)
                            Label(
                                "All Accounts",
                                systemImage: isAllSelected ? "checkmark.circle.fill" : "circle"
                            )
                        }
                        
                        Divider()
                        
                        ForEach(accounts) { account in
                            Button {
                                ui.toggleAccountSelected(for: account)
                            } label: {
                                let isSelected = ui.getAccountSelected(account: account)
                                Label(account.name, systemImage: account.iconName)
                                    .symbolVariant(isSelected ? .fill : .slash)
                            }
                        }
                    }
                } label: {
                    Label("Accounts", systemImage: ui.getAllAccountsSelected(accounts: accounts) ? "person.2.fill" : "person.2")
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
        @EnvironmentObject var ui: UIState
        
        var body: some View {
            Button {
                ui.createExpense(from: ExpenseDraft.createNew(with: context))
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
        @EnvironmentObject var ui: UIState
        
        var body: some View {
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
        @EnvironmentObject var ui: UIState
        
        var body: some View {
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
        @EnvironmentObject var ui: UIState
        
        var body: some View {
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
        @EnvironmentObject var ui: UIState
        
        var body: some View {
            Picker("View Mode", selection: $ui.selectedViewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Text(mode.localizedName)
                        .frame(minWidth: 60)
                        .tag(mode)
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
    .environmentObject(UIState())
    .environmentObject(UserSettings())
}
