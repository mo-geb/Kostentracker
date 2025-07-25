//
//  NotificationManagement.swift
//  Kostentracker
//

import SwiftUI
import UserNotifications
import UIKit

struct NotificationView: View {
    @State private var isNotificationsEnabled = false
    @State private var selectedNotificationDays: Set<NotificationDay> = []
    @State private var showSettingsAlert = false
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Manage Notifications")
                .navigationBarTitleDisplayMode(.inline)
                .alert("Notifications Disabled", isPresented: $showSettingsAlert) {
                    Button("Cancel", role: .cancel) {
                        isNotificationsEnabled = false
                    }
                    Button("Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                } message: {
                    Text("To enable notifications, please grant permission in Settings.")
                }
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
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    isNotificationsEnabled = true
                case .denied:
                    isNotificationsEnabled = false
                    showSettingsAlert = true
                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        DispatchQueue.main.async {
                            isNotificationsEnabled = granted
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}
