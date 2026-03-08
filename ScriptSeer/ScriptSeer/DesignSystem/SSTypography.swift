import SwiftUI

enum SSTypography {
    // Scalable fonts that respect Dynamic Type
    static let largeTitle = Font.system(.largeTitle, weight: .bold)
    static let title = Font.system(.title2, weight: .semibold)
    static let title2 = Font.system(.title3, weight: .semibold)
    static let headline = Font.system(.headline, weight: .semibold)
    static let body = Font.system(.body, weight: .regular)
    static let callout = Font.system(.callout, weight: .regular)
    static let subheadline = Font.system(.subheadline, weight: .regular)
    static let footnote = Font.system(.footnote, weight: .regular)
    static let caption = Font.system(.caption, weight: .regular)

    // Prompt text stays fixed-size (user controls size via slider)
    static func promptText(size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }
}
