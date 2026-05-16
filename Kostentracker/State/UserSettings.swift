import Foundation
import SwiftUI

@Observable
final class UserSettings {
    // Currency
    var currencyCode: String { didSet { UserDefaults.standard.set(currencyCode, forKey: "currencyCode") }}

    // Accounts
    var enableAccounts: Bool { didSet { UserDefaults.standard.set(enableAccounts, forKey: "enableAccounts") }}
    
    init() {
        let defaults = UserDefaults.standard
        
        self.currencyCode = defaults.string(forKey: "currencyCode") ?? "EUR"
        self.enableAccounts = defaults.bool(forKey: "enableAccounts") // default false
    }
}
