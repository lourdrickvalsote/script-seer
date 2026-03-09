import SwiftUI
import SwiftData

struct PracticeHistoryView: View {
    let script: Script

    private var sortedRecords: [PracticeRecord] {
        script.practiceRecords.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if sortedRecords.isEmpty {
                VStack {
                    Spacer()
                    SSEmptyState(
                        icon: "clock",
                        title: "No Practice History",
                        subtitle: "Complete a practice session to see your history here."
                    )
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: SSSpacing.sm) {
                        ForEach(sortedRecords, id: \.id) { record in
                            practiceRecordRow(record)
                        }
                    }
                    .padding(.horizontal, SSSpacing.md)
                    .padding(.vertical, SSSpacing.md)
                }
            }
        }
        .background(SSColors.background)
        .navigationTitle("Practice History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .preference(key: HideRecordButtonKey.self, value: true)
    }

    private func practiceRecordRow(_ record: PracticeRecord) -> some View {
        SSCard {
            VStack(alignment: .leading, spacing: SSSpacing.sm) {
                HStack {
                    Text(record.date.formatted(.relative(presentation: .named)))
                        .font(SSTypography.headline)
                        .foregroundStyle(SSColors.textPrimary)

                    Spacer()

                    if record.usedSpeechFollow {
                        HStack(spacing: SSSpacing.xxs) {
                            Image(systemName: "waveform")
                                .font(.system(size: 10))
                            Text("Smart Follow")
                                .font(SSTypography.caption)
                        }
                        .foregroundStyle(SSColors.accent)
                        .padding(.horizontal, SSSpacing.xs)
                        .padding(.vertical, SSSpacing.xxxs)
                        .background(
                            Capsule()
                                .fill(SSColors.accentSubtle)
                        )
                    }
                }

                HStack(spacing: SSSpacing.md) {
                    HStack(spacing: SSSpacing.xxs) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(formatDuration(record.duration))
                    }

                    HStack(spacing: SSSpacing.xxs) {
                        Image(systemName: "gauge.medium")
                            .font(.system(size: 12))
                        Text("\(Int(record.wordsPerMinute)) wpm")
                    }

                    if record.stumbleCount > 0 {
                        HStack(spacing: SSSpacing.xxs) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 12))
                            Text("\(record.stumbleCount)")
                        }
                        .foregroundStyle(SSColors.recordingRed)
                    }
                }
                .font(SSTypography.caption)
                .foregroundStyle(SSColors.textSecondary)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
