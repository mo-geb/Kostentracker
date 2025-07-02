//
//  MainTabView.swift
//  Kostentracker
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
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
    }
}
