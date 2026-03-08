import SwiftUI

enum SSButtonVariant {
    case primary
    case secondary
    case ghost
    case destructive
}

struct SSButton: View {
    let title: String
    let icon: String?
    let variant: SSButtonVariant
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        variant: SSButtonVariant = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.action = action
    }

    var body: some View {
        Button(action: {
            SSHaptics.light()
            action()
        }) {
            HStack(spacing: SSSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(SSTypography.headline)
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, SSSpacing.lg)
            .padding(.vertical, SSSpacing.sm)
            .frame(maxWidth: variant == .ghost ? nil : .infinity)
            .background(backgroundView)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: SSColors.lavenderMist
        case .secondary: SSColors.accent
        case .ghost: SSColors.textSecondary
        case .destructive: SSColors.recordingRed
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: SSRadius.md)
                .fill(SSColors.accent)
        case .secondary:
            RoundedRectangle(cornerRadius: SSRadius.md)
                .fill(SSColors.accentSubtle)
        case .ghost:
            Color.clear
        case .destructive:
            RoundedRectangle(cornerRadius: SSRadius.md)
                .fill(SSColors.recordingRedSubtle)
        }
    }
}
