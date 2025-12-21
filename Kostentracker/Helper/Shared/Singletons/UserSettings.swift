import Foundation
import SwiftUI

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    // Currency
    @AppStorage("currencyCode") var currencyCode: String = "EUR"
    
    // Notifications
    @AppStorage("isNotificationsEnabled") var isNotificationsEnabled: Bool = false
    @AppStorage("useDailySummaryNotifications") var useDailySummaryNotifications: Bool = true
    @AppStorage("repeatOverdueNotifications") var repeatOverdueNotifications: Bool = true


    // Accounts
    @AppStorage("enableAccounts") var enableAccounts: Bool = false
    
}
