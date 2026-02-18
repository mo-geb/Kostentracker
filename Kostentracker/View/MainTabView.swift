import SwiftUI

struct MainTabView: View {
    @Environment(UIState.self) var ui

    var body: some View {
        @Bindable var ui = ui
        
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
            NavigationStack {
                switch sheet {
                case .view(let e): ExpenseInspector(initialState: .view(e))
                case .new(let d):  ExpenseInspector(initialState: .new(d))
                case .edit(let e): ExpenseInspector(initialState: .edit(e))
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
