import UIKit

/// A centralized manager to easily trigger haptic feedback without injecting generators everywhere.
class HapticManager {
    static let shared = HapticManager()
    
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [
        .light: UIImpactFeedbackGenerator(style: .light),
        .medium: UIImpactFeedbackGenerator(style: .medium),
        .heavy: UIImpactFeedbackGenerator(style: .heavy)
    ]
    
    private init() {}
    
    /// Trigger a standard tactile 'impact' tap (e.g. for confirming toggles, switching tabs).
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = shared.impactGenerators[style] ?? UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger a notification feedback (e.g. success or error).
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        shared.notificationGenerator.prepare()
        shared.notificationGenerator.notificationOccurred(type)
    }
    
    /// Trigger the subtle selection feedback (e.g. picking emojis or scrolling intervals).
    static func selection() {
        shared.selectionGenerator.prepare()
        shared.selectionGenerator.selectionChanged()
    }
}
