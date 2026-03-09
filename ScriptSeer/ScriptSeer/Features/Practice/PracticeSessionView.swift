import SwiftUI

struct PracticeSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State var practiceSession: PracticeSession
    @State private var timer: Timer?
    @State private var tick: Int = 0 // forces time display updates

    init(script: Script) {
        self._practiceSession = State(initialValue: PracticeSession(script: script))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stats bar
            practiceStatsBar

            if practiceSession.isActive {
                // Active practice
                activePracticeView
            } else if practiceSession.endTime != nil {
                // Results
                PracticeResultsView(session: practiceSession, onRetryLine: retryFromLine, onDismiss: { dismiss() })
            } else {
                // Ready to start
                readyView
            }
        }
        .background(SSColors.background)
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopTimer() }
    }

    // MARK: - Stats Bar

    private var practiceStatsBar: some View {
        HStack(spacing: SSSpacing.lg) {
            Label(practiceSession.formattedElapsedTime, systemImage: "clock")
            Label("\(practiceSession.stumbles.count) stumbles", systemImage: "exclamationmark.triangle")
            Spacer()
            if practiceSession.isActive {
                Text("Line \(practiceSession.currentLineIndex + 1)/\(practiceSession.lines.count)")
            }
        }
        .font(SSTypography.caption)
        .foregroundStyle(SSColors.textTertiary)
        .padding(.horizontal, SSSpacing.md)
        .padding(.vertical, SSSpacing.xs)
        .background(SSColors.surface)
        .id(tick) // force refresh
    }

    // MARK: - Ready View

    private var readyView: some View {
        VStack(spacing: SSSpacing.lg) {
            Spacer()

            Image(systemName: "mic.badge.xmark")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(SSColors.textTertiary)

            Text("Ready to Practice")
                .font(SSTypography.title)
                .foregroundStyle(SSColors.textPrimary)

            Text("Read through your script at your own pace. Tap the stumble button when you trip over a line.")
                .font(SSTypography.subheadline)
                .foregroundStyle(SSColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SSSpacing.xl)

            SSButton("Start Practice", icon: "play.fill", variant: .primary) {
                practiceSession.start()
                startTimer()
                SSHaptics.medium()
            }
            .frame(width: 200)

            Spacer()
        }
    }

    // MARK: - Active Practice

    private var activePracticeView: some View {
        VStack(spacing: SSSpacing.md) {
            // Script content with current line highlighted
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: SSSpacing.sm) {
                        ForEach(Array(practiceSession.lines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(SSTypography.body)
                                .foregroundStyle(lineColor(for: index))
                                .lineSpacing(6)
                                .padding(.vertical, SSSpacing.xxs)
                                .id(index)
                                .onTapGesture {
                                    practiceSession.goToLine(index)
                                    SSHaptics.selection()
                                }
                        }
                    }
                    .padding(.horizontal, SSSpacing.md)
                    .padding(.vertical, SSSpacing.sm)
                }
                .onChange(of: practiceSession.currentLineIndex) { _, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }

            // Controls
            HStack(spacing: SSSpacing.lg) {
                // Stumble
                Button(action: {
                    practiceSession.markStumble()
                    SSHaptics.medium()
                }) {
                    Label("Stumble", systemImage: "exclamationmark.triangle")
                        .font(SSTypography.headline)
                        .foregroundStyle(SSColors.recordingRed)
                        .padding(.horizontal, SSSpacing.md)
                        .padding(.vertical, SSSpacing.sm)
                        .background(SSColors.recordingRedSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
                }

                // Next line
                Button(action: {
                    practiceSession.advanceLine()
                    SSHaptics.light()
                }) {
                    Label("Next", systemImage: "arrow.down")
                        .font(SSTypography.headline)
                        .foregroundStyle(SSColors.accent)
                        .padding(.horizontal, SSSpacing.md)
                        .padding(.vertical, SSSpacing.sm)
                        .background(SSColors.accentSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
                }

                // Finish
                Button(action: {
                    practiceSession.finish()
                    stopTimer()
                    SSHaptics.success()
                }) {
                    Label("Done", systemImage: "checkmark")
                        .font(SSTypography.headline)
                        .foregroundStyle(SSColors.textPrimary)
                        .padding(.horizontal, SSSpacing.md)
                        .padding(.vertical, SSSpacing.sm)
                        .background(SSColors.surfaceGlass)
                        .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
                }
            }
            .padding(.horizontal, SSSpacing.md)
            .padding(.bottom, SSSpacing.md)
        }
    }

    private func lineColor(for index: Int) -> Color {
        if index == practiceSession.currentLineIndex {
            return SSColors.textPrimary
        } else if index < practiceSession.currentLineIndex {
            return SSColors.textTertiary
        } else {
            return SSColors.textSecondary
        }
    }

    // MARK: - Timer

    private func startTimer() {
        let t = Timer(timeInterval: 1.0, repeats: true) { _ in
            tick += 1
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func retryFromLine(_ index: Int) {
        practiceSession.startFrom(line: index)
        stopTimer()
        startTimer()
    }
}
