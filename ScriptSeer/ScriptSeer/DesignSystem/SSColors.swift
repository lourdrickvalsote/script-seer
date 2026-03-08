import SwiftUI

enum SSColors {
    // MARK: - Brand Palette

    /// #0c120c — Near-black forest green
    static let darkForest = Color(red: 12/255, green: 18/255, blue: 12/255)
    /// #c20114 — Bold crimson red
    static let crimson = Color(red: 194/255, green: 1/255, blue: 20/255)
    /// #6d7275 — Medium slate gray
    static let slate = Color(red: 109/255, green: 114/255, blue: 117/255)
    /// #c7d6d5 — Cool silver sage
    static let silverSage = Color(red: 199/255, green: 214/255, blue: 213/255)
    /// #ecebf3 — Soft lavender mist
    static let lavenderMist = Color(red: 236/255, green: 235/255, blue: 243/255)

    // MARK: - Semantic Tokens (Adaptive)

    // Backgrounds
    static let background = Color(
        light: lavenderMist,
        dark: darkForest
    )
    static let surface = Color(
        light: .white,
        dark: Color(red: 20/255, green: 26/255, blue: 20/255)
    )
    static let surfaceElevated = Color(
        light: .white,
        dark: Color(red: 28/255, green: 34/255, blue: 28/255)
    )
    static let surfaceGlass = Color(
        light: slate.opacity(0.08),
        dark: silverSage.opacity(0.06)
    )

    // Text
    static let textPrimary = Color(
        light: darkForest,
        dark: lavenderMist
    )
    static let textSecondary = Color(
        light: slate,
        dark: silverSage
    )
    static let textTertiary = Color(
        light: slate.opacity(0.6),
        dark: slate
    )

    // Accent
    static let accent = Color(
        light: crimson,
        dark: Color(red: 220/255, green: 40/255, blue: 55/255)
    )
    static let accentSubtle = Color(
        light: crimson.opacity(0.12),
        dark: crimson.opacity(0.15)
    )

    // Recording (uses brand crimson)
    static let recordingRed = crimson
    static let recordingRedSubtle = Color(
        light: crimson.opacity(0.12),
        dark: crimson.opacity(0.15)
    )

    // Structural
    static let divider = Color(
        light: slate.opacity(0.15),
        dark: silverSage.opacity(0.08)
    )
    static let shadow = Color(
        light: darkForest.opacity(0.20),
        dark: darkForest.opacity(0.40)
    )
}

// MARK: - Adaptive Color Initializer

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
