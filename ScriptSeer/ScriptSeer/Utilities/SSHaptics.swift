import UIKit

enum SSHaptics {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func light() {
        lightGenerator.impactOccurred()
    }

    static func medium() {
        mediumGenerator.impactOccurred()
    }

    static func selection() {
        selectionGenerator.selectionChanged()
    }

    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}
