import SwiftUI

struct OnboardingSpeechFollowPage: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var headlineVisible = false
    @State private var subheadlineVisible = false
    @State private var visualVisible = false
    @State private var highlightedWordIndex = 0
    @State private var animationTimer: Timer?
    @State private var waveformTick = 0
    @State private var waveformTimer: Timer?

    private let barCount = 24
    private let words = [
        "Welcome", "everyone,", "today", "I", "want", "to",
        "share", "something", "that", "changed", "how", "I",
        "think", "about", "presenting", "on", "camera."
    ]

    var body: some View {
        VStack(spacing: SSSpacing.lg) {
            Spacer()

            // Waveform + text visual
            VStack(spacing: SSSpacing.xl) {
                // Waveform bars
                waveformView
                    .frame(height: 60)

                // Words with progressive highlight
                wordHighlightView
            }
            .opacity(visualVisible ? 1 : 0)
            .scaleEffect(visualVisible ? 1 : 0.95)

            Spacer().frame(height: SSSpacing.md)

            VStack(spacing: SSSpacing.sm) {
                Text("It listens. It follows.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(SSColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(headlineVisible ? 1 : 0)
                    .offset(y: headlineVisible ? 0 : 20)

                Text("Speak naturally. Your script\nkeeps pace with your voice.")
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

    private var waveformView: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                let seed = (waveformTick &* (index + 1)) % 100
                let height: CGFloat = isActive && !reduceMotion
                    ? CGFloat(12 + seed % 40)
                    : 20
                RoundedRectangle(cornerRadius: 2)
                    .fill(SSColors.accent.opacity(0.7))
                    .frame(width: 4, height: height)
                    .animation(.easeInOut(duration: 0.4), value: waveformTick)
            }
        }
        .accessibilityHidden(true)
    }

    private var wordHighlightView: some View {
        FlowLayout(spacing: SSSpacing.xxs) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .font(.system(size: 16, weight: index < highlightedWordIndex ? .semibold : .regular))
                    .foregroundStyle(
                        index < highlightedWordIndex
                            ? SSColors.textPrimary
                            : SSColors.textTertiary
                    )
                    .overlay(alignment: .bottom) {
                        if index < highlightedWordIndex {
                            Rectangle()
                                .fill(SSColors.accent)
                                .frame(height: 2)
                                .offset(y: 4)
                        }
                    }
                    .animation(SSAnimation.quick, value: highlightedWordIndex)
            }
        }
        .frame(maxWidth: 280)
        .padding(.horizontal, SSSpacing.lg)
        .accessibilityLabel("Script text highlighting progressively as words are spoken")
    }

    private func startAnimations() {
        if reduceMotion {
            visualVisible = true
            headlineVisible = true
            subheadlineVisible = true
            highlightedWordIndex = words.count
            return
        }

        withAnimation(SSAnimation.spring) {
            visualVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.3)) {
            headlineVisible = true
        }
        withAnimation(SSAnimation.smooth.delay(0.5)) {
            subheadlineVisible = true
        }

        // Waveform timer
        waveformTimer?.invalidate()
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            Task { @MainActor in
                guard isActive else { timer.invalidate(); return }
                waveformTick += 1
            }
        }

        // Word highlight timer
        highlightedWordIndex = 0
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            Task { @MainActor in
                guard isActive else { timer.invalidate(); return }
                if highlightedWordIndex < words.count {
                    highlightedWordIndex += 1
                } else {
                    highlightedWordIndex = 0
                }
            }
        }
    }

    private func resetAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
        waveformTimer?.invalidate()
        waveformTimer = nil
        waveformTick = 0
        visualVisible = false
        headlineVisible = false
        subheadlineVisible = false
        highlightedWordIndex = 0
    }
}

// Simple flow layout for wrapping words
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
