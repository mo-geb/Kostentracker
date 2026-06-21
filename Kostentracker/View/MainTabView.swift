import SwiftUI

struct MainTabView: View {
    @Environment(UIState.self) var uiState
    @State private var selectedTab: ActiveTab = .timeline

    var body: some View {
        @Bindable var ui = uiState
        
        TabView(selection: $selectedTab) {
            Tab("Timeline", systemImage: "calendar", value: .timeline) {
                TimelineView()
            }
            .accessibilityLabel("Timeline tab")
            .accessibilityHint("View expenses organized by date")
            
            Tab("List", systemImage: "list.bullet", value: .list) {
                ListView()
            }
            .accessibilityLabel("List tab")
            .accessibilityHint("View expenses in a categorized list")
            
            Tab("Statistics", systemImage: "chart.bar", value: .statistics) {
                StatisticsView()
            }
            .accessibilityLabel("Statistics tab")
            .accessibilityHint("View expense charts and analytics")
            
            Tab(value: .search, role: .search) {
                SearchView()
            }
            .accessibilityLabel("Search tab")
            .accessibilityHint("Search through your expenses")
        }
        .tabViewStyle(.automatic)
        .background(.thinMaterial)
        // Only new expenses are presented modally; existing ones are pushed.
        .sheet(item: $ui.activeExpenseSheet) { sheet in
            NavigationStack {
                ExpenseInspector(initialState: sheet, isPresentedAsSheet: true)
            }
        }
        .sheet(isPresented: $ui.showingSettings) {
            SettingsView()
        }
        .paywallSheet(isPresented: $ui.showingPaywall)
        .overlay {
            switch ui.activePopup {
            case .markedAsPaid(.main):
                MarkAsPaidPopup()
            case .deleted(.main):
                DeletedPopup()
            default:
                EmptyView()
            }
        }
    }
}

#Preview(traits: .modifier(PreviewModelContainer())) {
    NavigationStack {
        MainTabView()
            .environment(UIState())
            .environment(UserSettings())
            .environment(StoreManager())
    }
}
