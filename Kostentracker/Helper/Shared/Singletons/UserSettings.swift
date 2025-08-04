import Foundation
import SwiftUI

final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @AppStorage("currencyCode") var currencyCode: String = "EUR"
    @AppStorage("enableAccounts") var enableAccounts: Bool = false
}
