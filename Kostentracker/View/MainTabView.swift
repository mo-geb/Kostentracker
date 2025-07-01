//
//  MainTabView.swift
//  Kostentracker
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
            ListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
        }
        .tabViewStyle(.automatic)
        .background(.thinMaterial)
    }
}
