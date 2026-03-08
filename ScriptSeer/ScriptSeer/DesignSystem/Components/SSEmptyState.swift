import SwiftUI

struct SSEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: SSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(SSColors.textTertiary)

            VStack(spacing: SSSpacing.xs) {
                Text(title)
                    .font(SSTypography.title2)
                    .foregroundStyle(SSColors.textPrimary)

                Text(subtitle)
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                SSButton(actionTitle, variant: .secondary, action: action)
                    .padding(.top, SSSpacing.xs)
            }
        }
        .padding(SSSpacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}
