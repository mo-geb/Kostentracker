import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var ui: UIState

    var body: some View {
        TabView() {
            Tab("Timeline", systemImage: "calendar") {
                TimelineView()
            }
            Tab("List", systemImage: "list.bullet") {
                ListView()
            }
            Tab("Statistics", systemImage: "chart.bar") {
                StatisticsView()
            }
            Tab(role: .search) {
                SearchView()
            }
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
            if ui.activePopup == ActivePopup.markedAsPaid(owner: ActivePopup.MarkedAsPaidOwner.main) {
                MarkAsPaidPopup()
            }
        }
    }
}
