import SwiftUI

struct OnboardingRecordPage: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var headlineVisible = false
    @State private var subheadlineVisible = false
    @State private var viewfinderVisible = false
    @State private var recDotVisible = false
    @State private var elapsedSeconds = 0
    @State private var overlayScrollOffset: CGFloat = 0
    @State private var recordTimer: Timer?

    private let overlayText = "Welcome everyone, today I want to share something that changed how I think about presenting on camera. For years I struggled with reading scripts naturally."

    var body: some View {
        VStack(spacing: SSSpacing.lg) {
            Spacer()

            // Mock camera viewfinder
            viewfinderView
                .opacity(viewfinderVisible ? 1 : 0)
                .scaleEffect(viewfinderVisible ? 1 : 0.9)

            VStack(spacing: SSSpacing.sm) {
                Text("Record with confidence.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(SSColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(headlineVisible ? 1 : 0)
                    .offset(y: headlineVisible ? 0 : 20)

                Text("Camera overlay keeps your script\nvisible while you film.")
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

    private var viewfinderView: some View {
        ZStack {
            // Dark gradient background (camera preview mock)
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.08, blue: 0.1),
                            Color(red: 0.12, green: 0.12, blue: 0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 260, height: 200)

            // Corner brackets
            cornerBrackets
                .frame(width: 240, height: 180)

            // REC indicator
            HStack(spacing: SSSpacing.xxs) {
                Circle()
                    .fill(SSColors.recordingRed)
                    .frame(width: 8, height: 8)
                    .opacity(recDotVisible ? 1 : 0.3)

                Text("REC")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(SSColors.recordingRed)

                Text(timecodeString)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .offset(x: -60, y: -76)

            // Script overlay bar at bottom of viewfinder
            VStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.6))
                        .frame(height: 44)

                    Text(overlayText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                        .frame(width: 230, alignment: .leading)
                        .offset(x: -overlayScrollOffset)
                }
                .frame(width: 240)
                .padding(.bottom, SSSpacing.xs)
            }
            .frame(height: 200)
        }
        .accessibilityHidden(true)
    }

    private var cornerBrackets: some View {
        ZStack {
            // Top-left
            CornerBracket()
                .stroke(.white.opacity(0.5), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .position(x: 10, y: 10)

            // Top-right
            CornerBracket()
                .stroke(.white.opacity(0.5), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(90))
                .position(x: 230, y: 10)

            // Bottom-left
            CornerBracket()
                .stroke(.white.opacity(0.5), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(-90))
                .position(x: 10, y: 170)

            // Bottom-right
            CornerBracket()
                .stroke(.white.opacity(0.5), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(180))
                .position(x: 230, y: 170)
        }
    }

    private var timecodeString: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func startAnimations() {
        if reduceMotion {
            viewfinderVisible = true
            headlineVisible = true
            subheadlineVisible = true
            recDotVisible = true
            elapsedSeconds = 5
            return
        }

        withAnimation(SSAnimation.spring) {
            viewfinderVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.3)) {
            headlineVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.5)) {
            subheadlineVisible = true
        }

        // REC dot pulse
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(0.5)) {
            recDotVisible = true
        }

        // Timecode counter
        elapsedSeconds = 0
        recordTimer?.invalidate()
        recordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                guard isActive else { timer.invalidate(); return }
                elapsedSeconds += 1
            }
        }

        // Overlay text scroll
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false).delay(0.8)) {
            overlayScrollOffset = 100
        }
    }

    private func resetAnimations() {
        recordTimer?.invalidate()
        recordTimer = nil
        viewfinderVisible = false
        headlineVisible = false
        subheadlineVisible = false
        recDotVisible = false
        elapsedSeconds = 0
        overlayScrollOffset = 0
    }
}

// L-shaped corner bracket
struct CornerBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY * 0.4))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.4, y: rect.minY))
        return path
    }
}
