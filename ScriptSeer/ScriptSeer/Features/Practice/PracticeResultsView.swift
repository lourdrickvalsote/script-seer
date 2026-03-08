import SwiftUI

struct PracticeResultsView: View {
    let session: PracticeSession
    let onRetryLine: (Int) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: SSSpacing.lg) {
                // Summary
                SSGlassPanel {
                    VStack(spacing: SSSpacing.md) {
                        Text("Practice Complete")
                            .font(SSTypography.title2)
                            .foregroundStyle(SSColors.textPrimary)

                        HStack(spacing: SSSpacing.xl) {
                            ResultStat(label: "Time", value: session.formattedElapsedTime, icon: "clock")
                            ResultStat(label: "Pace", value: "\(Int(session.wordsPerMinute)) wpm", icon: "speedometer")
                            ResultStat(label: "Stumbles", value: "\(session.stumbles.count)", icon: "exclamationmark.triangle")
                        }

                        Text(session.paceDescription)
                            .font(SSTypography.subheadline)
                            .foregroundStyle(SSColors.accent)
                    }
                }
                .padding(.horizontal, SSSpacing.md)

                // Stumble review
                if !session.stumbles.isEmpty {
                    VStack(alignment: .leading, spacing: SSSpacing.sm) {
                        SSSectionHeader("Lines to Review")

                        ForEach(session.stumbles) { stumble in
                            SSCard {
                                VStack(alignment: .leading, spacing: SSSpacing.xs) {
                                    Text("Line \(stumble.lineIndex + 1)")
                                        .font(SSTypography.caption)
                                        .foregroundStyle(SSColors.textTertiary)

                                    Text(stumble.lineText)
                                        .font(SSTypography.body)
                                        .foregroundStyle(SSColors.textPrimary)
                                        .lineLimit(3)

                                    Button(action: { onRetryLine(stumble.lineIndex) }) {
                                        Label("Retry from here", systemImage: "arrow.counterclockwise")
                                            .font(SSTypography.caption)
                                            .foregroundStyle(SSColors.accent)
                                    }
                                    .padding(.top, SSSpacing.xxs)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal, SSSpacing.md)
                } else {
                    SSEmptyState(
                        icon: "star.fill",
                        title: "No Stumbles!",
                        subtitle: "Great job — you read through without any marked stumbles."
                    )
                }

                SSButton("Done", variant: .secondary, action: onDismiss)
                    .padding(.horizontal, SSSpacing.md)
            }
            .padding(.top, SSSpacing.lg)
        }
    }
}

private struct ResultStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: SSSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SSColors.accent)
            Text(value)
                .font(SSTypography.headline)
                .foregroundStyle(SSColors.textPrimary)
            Text(label)
                .font(SSTypography.caption)
                .foregroundStyle(SSColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
