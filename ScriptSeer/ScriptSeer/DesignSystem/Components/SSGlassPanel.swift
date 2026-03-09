import SwiftUI

struct SSGlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(SSSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: SSRadius.lg)
                    .fill(SSColors.surfaceElevated)
            )
            .shadow(color: SSColors.shadow, radius: 6, x: 0, y: 2)
    }
}
