import SwiftUI

struct PracticeResultsView: View {
    let session: PracticeSession
    let onRetryLine: (Int) -> Void
    let onDismiss: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPerfect: Bool { session.stumbles.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                        .padding(.top, SSSpacing.xl)
                        .padding(.bottom, SSSpacing.lg)

                    statsSection
                        .padding(.horizontal, SSSpacing.md)
                        .padding(.bottom, SSSpacing.lg)

                    if session.usedSpeechFollow {
                        speechFollowSection
                            .padding(.horizontal, SSSpacing.md)
                            .padding(.bottom, SSSpacing.lg)
                    }

                    if !session.stumbles.isEmpty {
                        stumbleSection
                            .padding(.horizontal, SSSpacing.md)
                            .padding(.bottom, SSSpacing.lg)
                    }
                }
            }

            // Actions pinned to bottom
            actionsSection
                .padding(.horizontal, SSSpacing.md)
                .padding(.top, SSSpacing.sm)
                .padding(.bottom, SSSpacing.md)
                .background(SSColors.background)
        }
        .background(SSColors.background)
        .onAppear {
            guard !appeared else { return }
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: SSSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [SSColors.accent.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)

                Circle()
                    .fill(SSColors.surfaceElevated)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(SSColors.accent.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: SSColors.shadow, radius: 12, x: 0, y: 4)

                Image(systemName: isPerfect ? "checkmark.circle.fill" : "flag.checkered")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(SSColors.accent)
                    .symbolEffect(.bounce, value: appeared)
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: SSSpacing.xs) {
                Text(isPerfect ? "Perfect Run!" : "Practice Complete")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(SSColors.textPrimary)

                Text(isPerfect
                     ? "No stumbles — you nailed it."
                     : "\(session.stumbles.count) stumble\(session.stumbles.count == 1 ? "" : "s") to review")
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(spacing: SSSpacing.sm) {
            statRow(
                value: session.formattedElapsedTime,
                label: "Time",
                icon: "clock",
                delay: 0.1
            )

            statRow(
                value: "\(Int(session.wordsPerMinute)) wpm",
                label: "Pace",
                icon: "gauge.with.needle",
                sublabel: session.paceDescription,
                delay: 0.2
            )

            statRow(
                value: "\(session.stumbles.count)",
                label: "Stumbles",
                icon: "exclamationmark.triangle",
                delay: 0.3
            )
        }
    }

    private func statRow(
        value: String,
        label: String,
        icon: String,
        sublabel: String? = nil,
        delay: Double
    ) -> some View {
        HStack(spacing: SSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SSColors.accent)
                .frame(width: 32, height: 32)
                .background(SSColors.accentSubtle)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(SSTypography.caption)
                    .foregroundStyle(SSColors.textTertiary)
                if let sublabel {
                    Text(sublabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SSColors.accent)
                }
            }

            Spacer()

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(SSColors.textPrimary)
        }
        .padding(.horizontal, SSSpacing.md)
        .padding(.vertical, SSSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: SSRadius.lg)
                .fill(SSColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: SSRadius.lg)
                        .stroke(SSColors.divider, lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.4).delay(delay),
            value: appeared
        )
    }

    // MARK: - Speech Follow Stats

    private var speechFollowSection: some View {
        let autoCount = session.stumbles.filter(\.isAutoDetected).count
        let manualCount = session.stumbles.count - autoCount

        return VStack(alignment: .leading, spacing: SSSpacing.sm) {
            HStack {
                Image(systemName: "waveform")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SSColors.accent)
                Text("Smart Follow")
                    .font(SSTypography.headline)
                    .foregroundStyle(SSColors.textPrimary)
            }
            .padding(.bottom, SSSpacing.xxs)

            HStack(spacing: SSSpacing.sm) {
                speechStatCard(
                    value: "\(autoCount)",
                    label: "Auto-detected",
                    icon: "waveform"
                )
                speechStatCard(
                    value: "\(manualCount)",
                    label: "Manual",
                    icon: "hand.tap"
                )
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.35),
            value: appeared
        )
    }

    private func speechStatCard(value: String, label: String, icon: String) -> some View {
        HStack(spacing: SSSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SSColors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(SSColors.textPrimary)
                Text(label)
                    .font(SSTypography.caption)
                    .foregroundStyle(SSColors.textTertiary)
            }

            Spacer()
        }
        .padding(SSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SSRadius.lg)
                .fill(SSColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: SSRadius.lg)
                        .stroke(SSColors.divider, lineWidth: 1)
                )
        )
    }

    // MARK: - Stumbles

    private var stumbleSection: some View {
        VStack(alignment: .leading, spacing: SSSpacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SSColors.accent)
                Text("Lines to Review")
                    .font(SSTypography.headline)
                    .foregroundStyle(SSColors.textPrimary)
            }
            .padding(.bottom, SSSpacing.xxs)

            ForEach(Array(session.stumbles.enumerated()), id: \.element.id) { index, stumble in
                stumbleCard(stumble: stumble, index: index)
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.4),
            value: appeared
        )
    }

    private func stumbleCard(stumble: StumbleMarker, index: Int) -> some View {
        VStack(alignment: .leading, spacing: SSSpacing.xs) {
            HStack {
                Text("Line \(stumble.lineIndex + 1)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SSColors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(SSColors.accentSubtle)
                    )

                if stumble.isAutoDetected {
                    HStack(spacing: 3) {
                        Image(systemName: "waveform")
                            .font(.system(size: 9, weight: .semibold))
                        Text("Auto")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(SSColors.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(SSColors.accentSubtle)
                    )
                }

                Spacer()

                Button {
                    onRetryLine(stumble.lineIndex)
                    SSHaptics.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Retry")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(SSColors.accent)
                }
            }

            Text(stumble.lineText)
                .font(SSTypography.body)
                .foregroundStyle(SSColors.textPrimary)
                .lineLimit(3)
        }
        .padding(SSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SSRadius.lg)
                .fill(SSColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: SSRadius.lg)
                        .stroke(SSColors.divider, lineWidth: 1)
                )
        )
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: SSSpacing.sm) {
            if !session.stumbles.isEmpty {
                Button {
                    SSHaptics.light()
                    onRetryLine(session.stumbles.first?.lineIndex ?? 0)
                } label: {
                    HStack(spacing: SSSpacing.xs) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Retry Stumbled Lines")
                            .font(SSTypography.headline)
                    }
                    .foregroundStyle(SSColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: SSRadius.md)
                            .fill(SSColors.accentSubtle)
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                SSHaptics.light()
                onDismiss()
            } label: {
                Text("Done")
                    .font(SSTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: SSRadius.md)
                            .fill(
                                LinearGradient(
                                    colors: [SSColors.accent, SSColors.accent.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: SSColors.accent.opacity(0.3), radius: 12, x: 0, y: 4)
                    )
            }
            .buttonStyle(.plain)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.5),
            value: appeared
        )
    }
}
