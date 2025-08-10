import SwiftUI
import UserNotifications
import UIKit

struct NotificationView: View {
    
    // MARK: - Properties
    // State
    @State private var showSettingsAlert = false
    @EnvironmentObject var settings: UserSettings
    @State private var selectedNotificationDays: Set<NotificationDay> = []
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Manage Notifications")
                .navigationBarTitleDisplayMode(.inline)
                .alert("Notifications Disabled", isPresented: $showSettingsAlert) {
                    Button("Cancel", role: .cancel) {
                        settings.isNotificationsEnabled = false
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
                Toggle("Enable Notifications", isOn: $settings.isNotificationsEnabled)
                    .onChange(of: settings.isNotificationsEnabled) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                    }
            } header: {
                Text("Notification Settings")
            } footer: {
                Text("Enable notifications to receive reminders about upcoming expenses")
            }
            
            if settings.isNotificationsEnabled {
                Section {
                    Toggle("Daily Summary Notifications", isOn: $settings.useDailySummaryNotifications)
                } footer: {
                    if settings.useDailySummaryNotifications {
                        Text("You receive one single notification sumarizing the amount of due and overdue expenses based on your schedule")
                    } else {
                        Text("You receive one notification per expense based on your schedule")
                    }
                }
                
                Section {
                    ForEach(NotificationDay.allCases, id: \.self) { day in
                        scheduleRow(day: day)
                    }
                } header: {
                    Text("Reminder Schedule")
                } footer: {
                    Text("Select when you want to be notified about upcoming expenses")
                }
                
                if selectedNotificationDays.contains(.overdue) {
                    Section {
                        Toggle("Repeat overdue Expenses", isOn: $settings.repeatOverdueNotifications)
                    } footer: {
                        if settings.repeatOverdueNotifications {
                            Text("You get notified about overdue expenses as long as they are not paid")
                        } else {
                            Text("You get notified about overdue expenses once")
                        }
                    }
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
        UNUserNotificationCenter.current().getNotificationSettings { systemSettings in
            DispatchQueue.main.async {
                switch systemSettings.authorizationStatus {
                case .authorized:
                    settings.isNotificationsEnabled = true
                case .denied:
                    settings.isNotificationsEnabled = false
                    showSettingsAlert = true
                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        DispatchQueue.main.async {
                            settings.isNotificationsEnabled = granted
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}

#Preview {
    return NavigationStack {
        NotificationView()
            .environmentObject(UIState())
            .environmentObject(UserSettings())
    }
}
