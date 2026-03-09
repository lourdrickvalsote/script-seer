import SwiftUI

struct OnboardingReadyPage: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var iconVisible = false
    @State private var headlineVisible = false
    @State private var accentLineVisible = false
    @State private var privacyVisible = false
    @State private var hapticFired = false

    var body: some View {
        VStack(spacing: SSSpacing.lg) {
            Spacer()

            // Icon
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(SSColors.accent)
                .opacity(iconVisible ? 1 : 0)
                .scaleEffect(iconVisible ? 1 : 0.7)

            // Headline
            Text("Look natural\non camera.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(SSColors.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(headlineVisible ? 1 : 0)
                .offset(y: headlineVisible ? 0 : 16)

            // Accent sub-headline
            Text("Every time.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(SSColors.accent)
                .opacity(accentLineVisible ? 1 : 0)
                .offset(y: accentLineVisible ? 0 : 12)

            // Privacy note
            Text("Your scripts stay private.\nEverything runs on-device.")
                .font(SSTypography.subheadline)
                .foregroundStyle(SSColors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(privacyVisible ? 1 : 0)
                .offset(y: privacyVisible ? 0 : 8)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, SSSpacing.lg)
        .onChange(of: isActive) { _, active in
            if active { startAnimations() } else { resetAnimations() }
        }
        .onAppear {
            if isActive { startAnimations() }
        }
    }

    private func startAnimations() {
        if reduceMotion {
            iconVisible = true
            headlineVisible = true
            accentLineVisible = true
            privacyVisible = true
            fireHaptic()
            return
        }

        withAnimation(SSAnimation.spring) {
            iconVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.2)) {
            headlineVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.45)) {
            accentLineVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.65)) {
            privacyVisible = true
        }

        // Fire haptic after full appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            fireHaptic()
        }
    }

    private func fireHaptic() {
        guard !hapticFired else { return }
        hapticFired = true
        SSHaptics.success()
    }

    private func resetAnimations() {
        iconVisible = false
        headlineVisible = false
        accentLineVisible = false
        privacyVisible = false
        hapticFired = false
    }
}
