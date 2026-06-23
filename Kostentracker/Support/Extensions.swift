import Foundation
import SwiftUI
import SwiftData

extension Color {
    func toHex() -> String? {
        if let components = cgColor?.components, components.count >= 3 {
            let r = Float(components[0])
            let g = Float(components[1])
            let b = Float(components[2])
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
        
        // Fallback for system colors - convert to a known color space
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return String(format: "%02lX%02lX%02lX",
                         lroundf(Float(red) * 255),
                         lroundf(Float(green) * 255),
                         lroundf(Float(blue) * 255))
        }
        
        return nil
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }

    var fullVersionString: String {
        "v\(appVersion) (Build \(buildNumber))"
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmojiPresentation || scalar.properties.generalCategory == .otherSymbol
    }
}

extension UserDefaults {
    func getEnum<T: RawRepresentable>(forKey key: String, default: T) -> T where T.RawValue == String {
        guard let rawValue = string(forKey: key),
              let value = T(rawValue: rawValue) else {
            return `default`
        }
        return value
    }
}

extension CaseIterable where Self: Equatable {
    mutating func cycleToNext() {
        let all = Self.allCases
        guard let idx = all.firstIndex(of: self) else { return }
        let next = all.index(after: idx)
        self = next == all.endIndex ? all[all.startIndex] : all[next]
    }
}

// MARK: - Expense detail navigation

/// Push destination for an existing expense. Viewing and editing an expense are
/// part of the browsing hierarchy, so they push; creating a new expense stays a
/// sheet (see `ActiveExpenseSheet.new`).
struct ExpenseDetailRoute: Hashable, Identifiable {
    let expense: Expense
    var startInEdit: Bool = false

    var id: PersistentIdentifier { expense.persistentModelID }

    static func == (lhs: ExpenseDetailRoute, rhs: ExpenseDetailRoute) -> Bool {
        lhs.expense.persistentModelID == rhs.expense.persistentModelID && lhs.startInEdit == rhs.startInEdit
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(expense.persistentModelID)
        hasher.combine(startInEdit)
    }
}

extension View {
    /// Pushes the expense inspector for the bound route. Pair with a row that sets
    /// the route on tap (`.view`) or via a context-menu Edit action (`startInEdit`).
    func expenseDetailDestination(_ route: Binding<ExpenseDetailRoute?>) -> some View {
        navigationDestination(item: route) { route in
            ExpenseInspector(initialState: route.startInEdit ? .edit(route.expense) : .view(route.expense))
        }
    }

    /// Shared inspector row: icon + label on the left, arbitrary content on the right.
    @ViewBuilder
    func inspectorRow<Content: View>(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(width: 20)
            }
            Text(title)
                .font(.callout)
            Spacer()
            content()
        }
        .padding(12)
        .cardSurface()
    }
}
