import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var ui: UIState

    var body: some View {
        TabView() {
            Tab("Timeline", systemImage: "calendar") {
                TimelineView()
            }
            .accessibilityLabel("Timeline tab")
            .accessibilityHint("View expenses organized by date")
            
            Tab("List", systemImage: "list.bullet") {
                ListView()
            }
            .accessibilityLabel("List tab")
            .accessibilityHint("View expenses in a categorized list")
            
            Tab("Statistics", systemImage: "chart.bar") {
                StatisticsView()
            }
            .accessibilityLabel("Statistics tab")
            .accessibilityHint("View expense charts and analytics")
            
            Tab(role: .search) {
                SearchView()
            }
            .accessibilityLabel("Search tab")
            .accessibilityHint("Search through your expenses")
        }
        .tabViewStyle(.automatic)
        .background(.thinMaterial)
        .sheet(item: $ui.activeExpenseSheet) { sheet in
            switch sheet {
            case .view(let expense):
                NavigationStack {
                    ExpenseInspector(initialState: .view(expense))
                }
            case .new(let draft):
                NavigationStack {
                    ExpenseInspector(initialState: .new(draft))
                }
            case .edit(let expense):
                NavigationStack {
                    ExpenseInspector(initialState: .edit(expense))
                }
            }
        }
        .sheet(isPresented: $ui.showingSettings) {
            SettingsView()
        }
        .overlay {
            if ui.activePopup == ActivePopup.markedAsPaid(owner: ActivePopup.PopupOwner.main) {
                MarkAsPaidPopup()
            }
            
            if ui.activePopup == ActivePopup.deleted(owner: ActivePopup.PopupOwner.main) {
                DeletedPopup()
            }
        }
    }
}
