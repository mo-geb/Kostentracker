import Foundation
import SwiftUI
import SwiftData

struct EmptyExpensesView: View {
    var body: some View {
        ContentUnavailableView(
            "No Expenses",
            systemImage: "tray",
            description: Text("Tap the + button to add your first expense.")
        )
    }
}

enum SharedToolbarElements {
    
    // MARK: - Toolbar Buttons
    struct SettingsButton: View {
        @EnvironmentObject var ui: UIState
        
        var body: some View {
            Button {
                ui.showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
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
        }
    }
    
    struct AddExpenseButton: View {
        @Environment(\.modelContext) private var context
        @EnvironmentObject var ui: UIState
        
        var body: some View {
            Button {
                ui.activeExpenseSheet = .new(ExpenseDraft.createNew(with: context))
            } label: {
                Label("Add Expense", systemImage: "plus")
            }
        }
    }
    
    // MARK: - Option Button Elements
    
    struct FilterPicker: View {
        @EnvironmentObject var ui: UIState
        
        var body: some View {
            Picker(selection: $ui.selectedFilter) {
                ForEach(FilterOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            } label: {
                Label("Filter By", systemImage: "line.3.horizontal.decrease.circle")
            }
            .pickerStyle(.menu)
        }
    }
    
    struct SortPicker: View {
        @EnvironmentObject var ui: UIState
        
        var body: some View {
            Picker(selection: $ui.selectedSort, label: Label("Sort By", systemImage: "arrow.up.arrow.down")) {
                ForEach(SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    struct GroupByPicker: View {
        @EnvironmentObject var ui: UIState
        
        var body: some View {
            Picker(selection: $ui.selectedGroupBy, label: Label("Group By", systemImage: "rectangle.3.group")) {
                ForEach(GroupByOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    struct ViewModePicker: View {
        @EnvironmentObject var ui: UIState
        
        var body: some View {
            Picker(selection: $ui.selectedViewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            } label: {
                Label("View Mode", systemImage: "list.bullet.rectangle")
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Sheets for shared elements
    
enum SharedSheets {
    @ViewBuilder
    static func expenseHandlingSheet(_ sheet: ActiveExpenseSheet) -> some View {
        switch sheet {
        case .view(let expense):
            NavigationStack {
                ExpenseDetailView(initialState: .view(expense))
            }
        case .new(let draft):
            NavigationStack {
                ExpenseDetailView(initialState: .new(draft))
            }
        case .edit(let expense):
            NavigationStack {
                ExpenseDetailView(initialState: .edit(expense))
            }
        }
    }
    
    static var settingsSheet: some View {
        SettingsView()
    }
}
