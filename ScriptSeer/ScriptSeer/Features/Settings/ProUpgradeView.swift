import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: SSSpacing.xl) {
                // Hero
                VStack(spacing: SSSpacing.md) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(SSColors.accent)

                    Text("ScriptSeer Pro")
                        .font(SSTypography.largeTitle)
                        .foregroundStyle(SSColors.textPrimary)

                    Text("Unlock the full teleprompter experience")
                        .font(SSTypography.subheadline)
                        .foregroundStyle(SSColors.textSecondary)
                }
                .padding(.top, SSSpacing.xl)

                // Features
                VStack(alignment: .leading, spacing: SSSpacing.md) {
                    ProFeatureRow(icon: "wand.and.stars", title: "AI Script Actions", subtitle: "Shorten, simplify, rewrite, and optimize scripts")
                    ProFeatureRow(icon: "waveform", title: "Speech Follow", subtitle: "Hands-free script advancement with voice")
                    ProFeatureRow(icon: "camera.fill", title: "Camera Overlay", subtitle: "Record with script overlay for eye contact")
                    ProFeatureRow(icon: "chart.bar", title: "Practice Analytics", subtitle: "Detailed feedback on your rehearsals")
                    ProFeatureRow(icon: "paintpalette", title: "Custom Themes", subtitle: "Additional high-contrast display themes")
                }
                .padding(.horizontal, SSSpacing.md)

                // CTA
                VStack(spacing: SSSpacing.sm) {
                    SSButton("Start Free Trial", icon: "star.fill", variant: .primary) {
                        // StoreKit 2 purchase flow would go here
                    }

                    Text("7-day free trial, then $4.99/month")
                        .font(SSTypography.caption)
                        .foregroundStyle(SSColors.textTertiary)

                    Text("Basic features always free. No lock-out.")
                        .font(SSTypography.caption)
                        .foregroundStyle(SSColors.textTertiary)
                }
                .padding(.horizontal, SSSpacing.md)
            }
        }
        .background(SSColors.background)
        .navigationTitle("Pro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct ProFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: SSSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(SSColors.accent)
                .frame(width: 40, height: 40)
                .background(SSColors.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))

            VStack(alignment: .leading, spacing: SSSpacing.xxxs) {
                Text(title)
                    .font(SSTypography.headline)
                    .foregroundStyle(SSColors.textPrimary)
                Text(subtitle)
                    .font(SSTypography.caption)
                    .foregroundStyle(SSColors.textSecondary)
            }
        }
    }
}
