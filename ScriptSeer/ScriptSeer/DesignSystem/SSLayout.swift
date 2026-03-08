import SwiftUI

/// Layout utilities for adaptive iPhone/iPad layouts
enum SSLayout {
    /// Whether the current device is an iPad
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Recommended content width for iPad (prevents ultra-wide text)
    static let iPadMaxContentWidth: CGFloat = 700

    /// Clamp a width for comfortable reading
    static func readableWidth(from available: CGFloat) -> CGFloat {
        if isIPad {
            return min(available, iPadMaxContentWidth)
        }
        return available
    }
}

/// Modifier that constrains content width on iPad for readability
struct ReadableWidthModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .frame(width: SSLayout.readableWidth(from: geometry.size.width))
                .frame(maxWidth: .infinity)
        }
    }
}

extension View {
    func readableWidth() -> some View {
        modifier(ReadableWidthModifier())
    }
}
