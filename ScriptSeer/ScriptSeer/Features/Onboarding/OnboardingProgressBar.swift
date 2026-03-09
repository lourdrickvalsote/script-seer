import SwiftUI

struct OnboardingProgressBar: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: SSSpacing.xxs) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? SSColors.accent : SSColors.textTertiary.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 4)
                    .animation(SSAnimation.spring, value: currentPage)
            }
        }
    }
}
