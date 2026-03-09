import UIKit

enum SSHaptics {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func light() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred()
    }

    static func medium() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
    }

    static func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }

    static func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    static func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
}
