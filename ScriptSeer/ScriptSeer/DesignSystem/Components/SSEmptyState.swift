import SwiftUI

struct SSEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: SSSpacing.md) {
            ZStack {
                Circle()
                    .fill(SSColors.accentSubtle)
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(SSColors.accent)
            }

            VStack(spacing: SSSpacing.xs) {
                Text(title)
                    .font(SSTypography.title2)
                    .foregroundStyle(SSColors.textPrimary)

                Text(subtitle)
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(SSSpacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
