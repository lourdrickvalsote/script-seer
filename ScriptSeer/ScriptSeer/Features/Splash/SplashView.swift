import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation phase states
    @State private var scanLineOffset: CGFloat = -1.0
    @State private var showScanLine = false
    @State private var iconBlur: CGFloat = 20
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 12
    @State private var dividerWidth: CGFloat = 0
    @State private var dissolveScale: CGFloat = 1.0
    @State private var dissolveOpacity: Double = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SSColors.background
                    .ignoresSafeArea()

                // Scan line
                if showScanLine {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, SSColors.accent, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .shadow(color: SSColors.accent.opacity(0.6), radius: 8, y: 0)
                        .offset(y: scanLineOffset * geometry.size.height / 2)
                }

                // Icon + wordmark composition
                VStack(spacing: SSSpacing.lg) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(SSColors.accent)
                        .blur(radius: iconBlur)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)

                    VStack(spacing: SSSpacing.xs) {
                        HStack(spacing: 0) {
                            Text("Script")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(SSColors.textSecondary)
                            Text("Seer")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(SSColors.accent)
                        }
                        .opacity(wordmarkOpacity)
                        .offset(y: wordmarkOffset)

                        Rectangle()
                            .fill(SSColors.divider)
                            .frame(width: dividerWidth, height: 1)
                    }
                }
            }
            .scaleEffect(dissolveScale)
            .opacity(dissolveOpacity)
        }
        .ignoresSafeArea()
        .task {
            if reduceMotion {
                // Static display for 1s then dismiss
                iconBlur = 0
                iconScale = 1
                iconOpacity = 1
                wordmarkOpacity = 1
                wordmarkOffset = 0
                dividerWidth = 120
                try? await Task.sleep(for: .seconds(1))
                onComplete()
                return
            }

            await runAnimationSequence()
        }
    }

    private func runAnimationSequence() async {
        // Phase 1: Scan line sweep (0.0s–0.6s)
        showScanLine = true
        scanLineOffset = -1.0
        withAnimation(.easeInOut(duration: 0.6)) {
            scanLineOffset = 1.0
        }

        // Phase 2: Icon materializes (0.4s–1.0s)
        try? await Task.sleep(for: .milliseconds(400))
        withAnimation(.easeOut(duration: 0.2)) {
            showScanLine = false
        }
        withAnimation(SSAnimation.smooth) {
            iconBlur = 0
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // Phase 3: Wordmark reveals (1.0s–1.6s)
        try? await Task.sleep(for: .milliseconds(600))
        withAnimation(SSAnimation.smooth) {
            wordmarkOpacity = 1.0
            wordmarkOffset = 0
        }
        withAnimation(.easeInOut(duration: 0.4)) {
            dividerWidth = 120
        }

        // Phase 4: Dissolve to app (2.0s–2.5s)
        try? await Task.sleep(for: .milliseconds(800))
        withAnimation(.easeIn(duration: 0.5)) {
            dissolveScale = 1.05
            dissolveOpacity = 0
        }

        try? await Task.sleep(for: .milliseconds(500))
        onComplete()
    }
}
