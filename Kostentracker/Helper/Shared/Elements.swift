import Foundation
import SwiftUI
import SwiftData

// MARK: - Views
struct EmptyExpensesView: View {
    var body: some View {
        ContentUnavailableView(
            "No Expenses",
            systemImage: "tray",
            description: Text("Tap the + button to add your first expense.")
        )
    }
}

// MARK: - Popup
struct MarkAsPaidPopup: View {
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
                .padding(5)
            Text("Marked Expense\nas Paid")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.scale.combined(with: .opacity))
        .zIndex(99)
    }
}

// MARK: - Toolbar
enum SharedToolbarElements {
    struct SettingsButton: View {
        @EnvironmentObject var ui: UIState
        
        var body: some View {
            Button {
                ui.showSettings()
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
                ui.createExpense(from: ExpenseDraft.createNew(with: context))
            } label: {
                Label("Add Expense", systemImage: "plus")
            }
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

#Preview {
    MarkAsPaidPopup()
}
