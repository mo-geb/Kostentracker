//
//  NotificationManagement.swift
//  Kostentracker
//

import SwiftUI

struct NotificationManagementView: View {
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Manage Notifications")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        ContentUnavailableView(
            "Nothing to see here",
            systemImage: "tortoise",
            description: Text("But this is where you will be able to manage your notifications soon! 👁️👄👁️")
        )
    }
}
