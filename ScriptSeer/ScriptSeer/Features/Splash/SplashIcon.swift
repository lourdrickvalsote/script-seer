import SwiftUI

struct SplashIcon: View {
    let blur: CGFloat
    let scale: CGFloat
    let opacity: Double
    let animate: Bool
    let reduceMotion: Bool

    // Parallax offsets
    @State private var outerOffset: CGFloat = 0
    @State private var middleOffset: CGFloat = 0
    @State private var focusRotation: Double = 0

    private let size: CGFloat = 120

    var body: some View {
        ZStack {
            // Layer 1: Outer broken arc
            outerRing
                .offset(x: outerOffset, y: -outerOffset)

            // Layer 6: Tick marks on middle ring
            tickMarks

            // Layer 2: Middle full ring
            middleRing
                .offset(x: -middleOffset, y: middleOffset)

            // Layer 3: Inner broken arc
            innerRing

            // Layer 4: Script lines
            scriptLines

            // Layer 5: Focal point
            focalPoint
        }
        .frame(width: size, height: size)
        .blur(radius: blur)
        .scaleEffect(scale)
        .opacity(opacity)
        .onChange(of: animate) {
            guard animate, !reduceMotion else { return }
            startParallax()
        }
    }

    // MARK: - Layers

    private var outerRing: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(SSColors.accent.opacity(0.2), lineWidth: 2)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(-20 + focusRotation * 0.3))
    }

    private var middleRing: some View {
        Circle()
            .stroke(SSColors.accent.opacity(0.45), lineWidth: 2.5)
            .frame(width: size * 0.72, height: size * 0.72)
    }

    private var innerRing: some View {
        Circle()
            .trim(from: 0, to: 0.56)
            .stroke(SSColors.accent.opacity(0.7), lineWidth: 3)
            .frame(width: size * 0.48, height: size * 0.48)
            .rotationEffect(.degrees(130))
    }

    private var scriptLines: some View {
        VStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(SSColors.accent)
                .frame(width: 18, height: 3)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(SSColors.accent)
                .frame(width: 30, height: 3)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(SSColors.accent)
                .frame(width: 22, height: 3)
        }
        .offset(y: 2)
    }

    private var focalPoint: some View {
        Circle()
            .fill(SSColors.accent)
            .frame(width: 7, height: 7)
            .shadow(color: SSColors.accent.opacity(0.5), radius: 4)
            .offset(y: -(size * 0.48 / 2) + 6)
    }

    private var tickMarks: some View {
        let radius = size * 0.72 / 2
        return ZStack {
            ForEach(0..<4) { i in
                let angle = Angle.degrees(Double(i) * 90)
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(SSColors.accent.opacity(0.3))
                    .frame(width: 1.5, height: 8)
                    .offset(y: -radius)
                    .rotationEffect(angle)
            }
        }
    }

    // MARK: - Animation

    private func startParallax() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            outerOffset = 2
        }
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            middleOffset = 1
        }
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            focusRotation = 12
        }
    }
}
