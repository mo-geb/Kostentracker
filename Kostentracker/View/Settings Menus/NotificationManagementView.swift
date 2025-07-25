//
//  NotificationManagement.swift
//  Kostentracker
//

import SwiftUI
import UserNotifications

struct NotificationManagementView: View {
    @State private var isNotificationsEnabled = false
    @State private var selectedNotificationDays: Set<NotificationDay> = []
    
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
        List {
            Section {
                Toggle("Enable Notifications", isOn: $isNotificationsEnabled)
                    .onChange(of: isNotificationsEnabled) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                    }
            } header: {
                Text("Notification Settings")
            } footer: {
                Text("Enable notifications to receive reminders about upcoming expenses")
            }
            
            if isNotificationsEnabled {
                Section {
                    ForEach(NotificationDay.allCases, id: \.self) { day in
                        scheduleRow(day: day)
                    }
                } header: {
                    Text("Reminder Schedule")
                } footer: {
                    Text("Select when you want to be notified about upcoming expenses")
                }
            }
        }
    }
    
    @ViewBuilder
    private func scheduleRow(day: NotificationDay) -> some View {
        let isSelected = selectedNotificationDays.contains(day)
        
        Button {
            if selectedNotificationDays.contains(day) {
                selectedNotificationDays.remove(day)
            } else {
                selectedNotificationDays.insert(day)
            }
        } label: {
            HStack {
                Text(day.description)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .foregroundColor(.primary)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    isNotificationsEnabled = false
                }
            }
        }
    }
}
