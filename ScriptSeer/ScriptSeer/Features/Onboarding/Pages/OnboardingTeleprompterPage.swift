import SwiftUI

struct OnboardingTeleprompterPage: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var headlineVisible = false
    @State private var subheadlineVisible = false
    @State private var phoneVisible = false
    @State private var scrollOffset: CGFloat = 0
    @State private var focusPulse = false

    private let scriptText = """
    Welcome everyone. Today I want to share something that changed how I think about presenting on camera. \
    For years I struggled with reading scripts naturally. My eyes would dart back and forth. \
    My delivery felt stiff and rehearsed. But then I discovered a better way. \
    By keeping the text right where I look, near the camera lens, \
    I could maintain eye contact while reading every word perfectly. \
    The result was transformative. My audience felt connected. \
    My message landed with impact. And I never had to memorize a single line.
    """

    var body: some View {
        VStack(spacing: SSSpacing.lg) {
            Spacer()

            // Mock phone frame with teleprompter
            phoneFrame
                .opacity(phoneVisible ? 1 : 0)
                .scaleEffect(phoneVisible ? 1 : 0.9)

            VStack(spacing: SSSpacing.sm) {
                Text("Your words.\nRight where you look.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(SSColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(headlineVisible ? 1 : 0)
                    .offset(y: headlineVisible ? 0 : 20)

                Text("Focus Window keeps text near the lens\nso you never break eye contact.")
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(subheadlineVisible ? 1 : 0)
                    .offset(y: subheadlineVisible ? 0 : 12)
            }
            .padding(.horizontal, SSSpacing.lg)

            Spacer()
            Spacer()
        }
        .onChange(of: isActive) { _, active in
            if active { startAnimations() } else { resetAnimations() }
        }
        .onAppear {
            if isActive { startAnimations() }
        }
    }

    private var phoneFrame: some View {
        ZStack {
            // Phone outline
            RoundedRectangle(cornerRadius: 24)
                .stroke(SSColors.textTertiary.opacity(0.3), lineWidth: 2)
                .frame(width: 180, height: 320)

            // Scrolling text inside phone
            ZStack {
                // Script text
                Text(scriptText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SSColors.textSecondary.opacity(0.4))
                    .lineSpacing(6)
                    .frame(width: 150)
                    .offset(y: -scrollOffset)

                // Focus window band
                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        // Glass background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(SSColors.accent.opacity(focusPulse ? 0.08 : 0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(SSColors.accent.opacity(focusPulse ? 0.4 : 0.2), lineWidth: 1)
                            )
                            .frame(height: 50)

                        // Bright text in focus zone
                        Text("I could maintain eye contact\nwhile reading every word")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SSColors.textPrimary)
                            .lineSpacing(6)
                            .frame(width: 150)
                    }
                    Spacer()
                    Spacer()
                }
            }
            .frame(width: 160, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            // Camera notch indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(SSColors.textTertiary.opacity(0.3))
                .frame(width: 50, height: 6)
                .offset(y: -153)
        }
        .accessibilityHidden(true)
    }

    private func startAnimations() {
        if reduceMotion {
            phoneVisible = true
            headlineVisible = true
            subheadlineVisible = true
            return
        }

        withAnimation(SSAnimation.spring) {
            phoneVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.3)) {
            headlineVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.5)) {
            subheadlineVisible = true
        }

        // Auto-scroll text
        startScrolling()

        // Focus band pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            focusPulse = true
        }
    }

    private func startScrolling() {
        guard !reduceMotion, isActive else { return }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            scrollOffset = 200
        }
    }

    private func resetAnimations() {
        phoneVisible = false
        headlineVisible = false
        subheadlineVisible = false
        scrollOffset = 0
        focusPulse = false
    }
}
