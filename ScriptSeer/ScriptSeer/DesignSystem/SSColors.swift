import SwiftUI

enum SSColors {
    // MARK: - Brand Palette

    /// #1A1A1A — Warm charcoal
    static let darkForest = Color(red: 26/255, green: 26/255, blue: 26/255)
    /// #B5202A — Deep garnet
    static let crimson = Color(red: 181/255, green: 32/255, blue: 42/255)
    /// #7A7F84 — Warm slate gray
    static let slate = Color(red: 122/255, green: 127/255, blue: 132/255)
    /// #C4C9CE — Warm silver gray
    static let silverSage = Color(red: 196/255, green: 201/255, blue: 206/255)
    /// #F5F3EF — Warm cream
    static let lavenderMist = Color(red: 245/255, green: 243/255, blue: 239/255)

    // MARK: - Semantic Tokens (Adaptive)

    // Backgrounds
    static let background = Color(
        light: lavenderMist,
        dark: Color(red: 22/255, green: 22/255, blue: 22/255)
    )
    static let surface = Color(
        light: .white,
        dark: Color(red: 30/255, green: 30/255, blue: 30/255)
    )
    static let surfaceElevated = Color(
        light: .white,
        dark: Color(red: 38/255, green: 38/255, blue: 38/255)
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
        dark: Color(red: 218/255, green: 68/255, blue: 78/255)
    )
    static let accentSubtle = Color(
        light: crimson.opacity(0.12),
        dark: crimson.opacity(0.15)
    )
    /// Warm accent tint for icon backgrounds
    static let accentWarm = Color(
        light: crimson.opacity(0.10),
        dark: Color(red: 218/255, green: 68/255, blue: 78/255).opacity(0.15)
    )

    // Recording (uses brand crimson)
    static let recordingRed = crimson
    static let recordingRedSubtle = Color(
        light: crimson.opacity(0.12),
        dark: crimson.opacity(0.15)
    )

    // Structural
    static let divider = Color(
        light: darkForest.opacity(0.08),
        dark: Color.white.opacity(0.06)
    )
    static let shadow = Color(
        light: Color(red: 26/255, green: 26/255, blue: 26/255).opacity(0.12),
        dark: Color.black.opacity(0.50)
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
