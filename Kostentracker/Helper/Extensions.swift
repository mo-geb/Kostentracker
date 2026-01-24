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
