import SwiftUI

struct AudioWaveformView: View {
    var level: Float
    var isRecording: Bool
    var size: WaveformSize = .compact

    enum WaveformSize {
        case compact
        case large

        var barCount: Int {
            switch self {
            case .compact: 12
            case .large: 28
            }
        }

        var barWidth: CGFloat {
            switch self {
            case .compact: 4
            case .large: 6
            }
        }

        var spacing: CGFloat {
            switch self {
            case .compact: 3
            case .large: 4
            }
        }

        var height: CGFloat {
            switch self {
            case .compact: 52
            case .large: 120
            }
        }

        var maxBarHeight: CGFloat {
            switch self {
            case .compact: 40
            case .large: 100
            }
        }

        var waveAmplitude: CGFloat {
            switch self {
            case .compact: 8
            case .large: 16
            }
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: size.spacing) {
                ForEach(0..<size.barCount, id: \.self) { index in
                    let phase = sin(time * 3.0 + Double(index) * 0.5)
                    let baseHeight: CGFloat = isRecording
                        ? CGFloat(level) * size.maxBarHeight + 4
                        : 4
                    let height = max(4, baseHeight + CGFloat(phase) * (isRecording ? size.waveAmplitude : 1))

                    RoundedRectangle(cornerRadius: size == .large ? 3 : 2)
                        .fill(.white.opacity(isRecording ? 0.6 + Double(level) * 0.3 : 0.2))
                        .frame(width: size.barWidth, height: height)
                }
            }
            .frame(height: size.height)
            .animation(.easeOut(duration: 0.1), value: level)
        }
    }
}
