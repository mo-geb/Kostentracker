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
        .sheet(isPresented: $ui.showingSettings) {
            SettingsView()
        }
    }
}
