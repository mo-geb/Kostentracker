import SwiftUI

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
        
        var body: some View {
            Menu {
                Picker(selection: $ui.selectedFilter) {
                    ForEach(FilterOption.allCases) { option in
                        Text(option.localizedName).tag(option)
                    }
                } label: {
                    Label("Filter By", systemImage: "line.3.horizontal.decrease.circle")
                }
                .pickerStyle(.inline)
            } label: {
                Label("Accounts", systemImage: "person.2")
            }
            .accessibilityLabel("Accounts filter")
            .accessibilityHint("Opens menu to filter expenses by account")
            .frame(minWidth: 44, minHeight: 44)
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
                ForEach(FilterOption.allCases.filter{ $0 != .active }) { option in
                    
                    Button {} label: {
                        Label(option.localizedName, systemImage: "")
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
                        Label(option.localizedName, systemImage: "")
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
                    Text(mode.localizedName).tag(mode)
                }
            }
            .pickerStyle(.palette)
            .accessibilityLabel("View Mode")
            .accessibilityHint("Switch between different display modes")
        }
    }
}
