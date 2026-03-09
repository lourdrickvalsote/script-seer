import SwiftUI

struct OnboardingProblemPage: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var headlineVisible = false
    @State private var subheadlineVisible = false
    @State private var scriptLinesVisible = false

    // Jitter offsets for each script line
    @State private var jitter1: CGFloat = 0
    @State private var jitter2: CGFloat = 0
    @State private var jitter3: CGFloat = 0

    private let scriptLines = [
        "Welcome everyone, today I want to talk about...",
        "...the key insights from our latest research on...",
        "...how technology is shaping the future of..."
    ]

    var body: some View {
        VStack(spacing: SSSpacing.xl) {
            Spacer()

            // Camera lens ring (decorative)
            ZStack {
                Circle()
                    .stroke(SSColors.textTertiary.opacity(0.15), lineWidth: 1.5)
                    .frame(width: 180, height: 180)
                    .accessibilityHidden(true)

                Circle()
                    .stroke(SSColors.textTertiary.opacity(0.08), lineWidth: 1)
                    .frame(width: 220, height: 220)
                    .accessibilityHidden(true)

                // Jittery script lines
                VStack(spacing: SSSpacing.sm) {
                    ForEach(Array(scriptLines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(SSTypography.caption)
                            .foregroundStyle(SSColors.textTertiary.opacity(0.6))
                            .lineLimit(1)
                            .offset(x: jitterOffset(for: index))
                    }
                }
                .frame(width: 200)
                .opacity(scriptLinesVisible ? 1 : 0)
                .accessibilityHidden(true)
            }

            VStack(spacing: SSSpacing.sm) {
                Text("Reading on camera\nis awkward.")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(SSColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(headlineVisible ? 1 : 0)
                    .offset(y: headlineVisible ? 0 : 20)

                Text("Your eyes dart. Your delivery stiffens.\nYour audience can tell.")
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

    private func jitterOffset(for index: Int) -> CGFloat {
        switch index {
        case 0: return jitter1
        case 1: return jitter2
        default: return jitter3
        }
    }

    private func startAnimations() {
        if reduceMotion {
            headlineVisible = true
            subheadlineVisible = true
            scriptLinesVisible = true
            return
        }

        withAnimation(SSAnimation.smooth) {
            headlineVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.2)) {
            subheadlineVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.5)) {
            scriptLinesVisible = true
        }

        // Start jitter loop
        startJitter()
    }

    private func startJitter() {
        guard !reduceMotion, isActive else { return }

        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            jitter1 = CGFloat.random(in: -4...4)
        }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.15)) {
            jitter2 = CGFloat.random(in: -5...5)
        }
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true).delay(0.3)) {
            jitter3 = CGFloat.random(in: -3...3)
        }
    }

    private func resetAnimations() {
        headlineVisible = false
        subheadlineVisible = false
        scriptLinesVisible = false
        jitter1 = 0
        jitter2 = 0
        jitter3 = 0
    }
}
