import SwiftUI

struct SSCard<Content: View>: View {
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
            .overlay(
                RoundedRectangle(cornerRadius: SSRadius.lg)
                    .stroke(SSColors.divider, lineWidth: 0.5)
            )
    }
}
