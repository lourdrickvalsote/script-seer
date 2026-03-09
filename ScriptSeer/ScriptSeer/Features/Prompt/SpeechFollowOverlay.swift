import SwiftUI

struct SpeechFollowOverlay: View {
    let engine: SpeechFollowEngine

    var body: some View {
        HStack(spacing: SSSpacing.xs) {
            // Pulsing dot
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .fill(statusColor.opacity(0.4))
                        .frame(width: 12, height: 12)
                        .opacity(engine.state == .following ? 1 : 0)
                        .scaleEffect(engine.state == .following ? 1.5 : 1)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: engine.state)
                )

            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))

            if engine.isConfidenceScrollEnabled {
                Text("·")
                    .foregroundStyle(.white.opacity(0.3))
                Text("\(Int(engine.speakingWPM)) wpm")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, SSSpacing.sm)
        .padding(.vertical, 6)
        .background(.black.opacity(0.5))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch engine.state {
        case .idle, .stopped: .gray
        case .listening: SSColors.accent
        case .following: .green
        case .lowConfidence: .orange
        case .manualAssist: SSColors.recordingRed
        }
    }

    private var statusText: String {
        switch engine.state {
        case .idle: "Ready"
        case .listening: "Listening"
        case .following: "Following"
        case .lowConfidence: "Low Confidence"
        case .manualAssist: "Manual"
        case .stopped: "Stopped"
        }
    }
}
