import SwiftUI

struct SpeechFollowOverlay: View {
    let engine: SpeechFollowEngine

    var body: some View {
        VStack {
            // Status indicator
            HStack(spacing: SSSpacing.xs) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(SSTypography.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                if engine.isConfidenceScrollEnabled {
                    Text("\(Int(engine.speakingWPM))wpm")
                        .font(SSTypography.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Text("\(Int(engine.progress * 100))%")
                    .font(SSTypography.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, SSSpacing.sm)
            .padding(.vertical, SSSpacing.xs)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))

            // Debug overlay
            if engine.showDebugOverlay {
                debugView
            }
        }
    }

    private var statusColor: Color {
        switch engine.state {
        case .idle, .stopped: SSColors.slate
        case .listening: SSColors.accent
        case .following: SSColors.silverSage
        case .lowConfidence: Color.orange
        case .manualAssist: SSColors.recordingRed
        }
    }

    private var statusText: String {
        switch engine.state {
        case .idle: "Ready"
        case .listening: "Listening..."
        case .following: "\(engine.mode.rawValue) · Following"
        case .lowConfidence: "Low Confidence"
        case .manualAssist: "Manual Assist"
        case .stopped: "Stopped"
        }
    }

    private var debugView: some View {
        VStack(alignment: .leading, spacing: SSSpacing.xxs) {
            Text("Debug — Confidence: \(String(format: "%.2f", engine.confidence))")
                .font(SSTypography.caption)
                .foregroundStyle(.white.opacity(0.7))

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(engine.debugLog.suffix(10), id: \.self) { entry in
                        Text(entry)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .frame(maxHeight: 120)
        }
        .padding(SSSpacing.xs)
        .background(Color.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))
    }
}
