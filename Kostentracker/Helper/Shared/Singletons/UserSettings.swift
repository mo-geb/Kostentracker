import Foundation
import SwiftUI

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    // Currency
    @AppStorage("currencyCode") var currencyCode: String = "EUR"

    // Accounts
    @AppStorage("enableAccounts") var enableAccounts: Bool = false
    
}
