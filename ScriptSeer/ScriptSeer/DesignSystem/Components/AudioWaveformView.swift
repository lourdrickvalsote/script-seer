import SwiftUI

struct AudioWaveformView: View {
    var level: Float
    var isRecording: Bool
    private let barCount = 12

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    let phase = sin(time * 3.0 + Double(index) * 0.5)
                    let baseHeight: CGFloat = isRecording
                        ? CGFloat(level) * 40 + 4
                        : 4
                    let height = max(4, baseHeight + CGFloat(phase) * (isRecording ? 8 : 1))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(isRecording ? 0.6 + Double(level) * 0.3 : 0.2))
                        .frame(width: 4, height: height)
                }
            }
            .frame(height: 52)
            .animation(.easeOut(duration: 0.1), value: level)
        }
    }
}
