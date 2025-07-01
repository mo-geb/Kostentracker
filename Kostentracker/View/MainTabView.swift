//
//  MainTabView.swift
//  Kostentracker
//
//  Created by Moritz Gebhardt on 29.06.25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var tracker: ExpenseTracker
    @State var searchText = ""
    
    var body: some View {
        TabView {
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
            
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
        }
        .tabViewStyle(.automatic)
        .background(.thinMaterial)
        .searchable(text: $searchText)
    }
}
