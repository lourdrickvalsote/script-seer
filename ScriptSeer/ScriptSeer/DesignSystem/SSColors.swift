import SwiftUI

enum SSColors {
    static let background = Color(red: 0.06, green: 0.06, blue: 0.07)
    static let surface = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let surfaceElevated = Color(red: 0.14, green: 0.14, blue: 0.15)
    static let surfaceGlass = Color.white.opacity(0.06)

    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.65)
    static let textTertiary = Color(white: 0.40)

    static let accent = Color(red: 0.55, green: 0.75, blue: 1.0)
    static let accentSubtle = accent.opacity(0.15)

    // Reserved for recording states only
    static let recordingRed = Color(red: 1.0, green: 0.25, blue: 0.25)
    static let recordingRedSubtle = recordingRed.opacity(0.15)

    static let divider = Color.white.opacity(0.08)
    static let shadow = Color.black.opacity(0.4)
}
