import SwiftUI

struct PracticeSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State var practiceSession: PracticeSession
    @State private var timer: Timer?
    @State private var tick: Int = 0

    init(script: Script) {
        self._practiceSession = State(initialValue: PracticeSession(script: script))
    }

    var body: some View {
        VStack(spacing: 0) {
            if practiceSession.isActive {
                activePracticeView
            } else if practiceSession.endTime != nil {
                PracticeResultsView(session: practiceSession, onRetryLine: retryFromLine, onDismiss: { dismiss() })
            } else {
                readyView
            }
        }
        .background(SSColors.background)
        .toolbar(.hidden, for: .tabBar)
        .preference(key: HideRecordButtonKey.self, value: true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopTimer() }
    }

    // MARK: - Ready View

    private var readyView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: SSSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(SSColors.accentSubtle)
                        .frame(width: 88, height: 88)

                    Image(systemName: "text.redaction")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(SSColors.accent)
                }

                VStack(spacing: SSSpacing.xs) {
                    Text("Practice Mode")
                        .font(SSTypography.largeTitle)
                        .foregroundStyle(SSColors.textPrimary)

                    Text(practiceSession.script.title)
                        .font(SSTypography.subheadline)
                        .foregroundStyle(SSColors.textTertiary)
                }

                Text("Read through your script at your own pace.\nMark any lines you stumble over for review.")
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()

            VStack(spacing: SSSpacing.md) {
                Button {
                    practiceSession.start()
                    startTimer()
                    SSHaptics.medium()
                } label: {
                    HStack(spacing: SSSpacing.xs) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Start Practice")
                            .font(SSTypography.headline)
                    }
                    .foregroundStyle(SSColors.lavenderMist)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
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

                Button("Back") { dismiss() }
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textTertiary)
            }
            .padding(.horizontal, SSSpacing.xl)
            .padding(.bottom, SSSpacing.xxl)
        }
    }

    // MARK: - Active Practice

    private var activePracticeView: some View {
        VStack(spacing: 0) {
            // Stats bar
            practiceStatsBar

            // Script content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: SSSpacing.xs) {
                        ForEach(Array(practiceSession.lines.enumerated()), id: \.offset) { index, line in
                            practiceLineView(index: index, line: line)
                        }
                    }
                    .padding(.horizontal, SSSpacing.md)
                    .padding(.vertical, SSSpacing.lg)
                }
                .onChange(of: practiceSession.currentLineIndex) { _, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }

            // Controls
            practiceControls
        }
    }

    private func practiceLineView(index: Int, line: String) -> some View {
        let isCurrent = index == practiceSession.currentLineIndex
        let isPast = index < practiceSession.currentLineIndex
        let isStumbled = practiceSession.stumbles.contains { $0.lineIndex == index }

        return HStack(alignment: .top, spacing: SSSpacing.sm) {
            // Line indicator
            if isCurrent {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(SSColors.accent)
                    .frame(width: 3, height: 20)
                    .padding(.top, 2)
            } else if isStumbled {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(SSColors.recordingRed)
                    .frame(width: 3)
                    .padding(.top, 3)
            } else {
                Color.clear.frame(width: 3)
            }

            Text(line)
                .font(SSTypography.body)
                .foregroundStyle(
                    isCurrent ? SSColors.textPrimary :
                    isPast ? SSColors.textTertiary :
                    SSColors.textSecondary
                )
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, SSSpacing.xxs)
        .padding(.horizontal, SSSpacing.xs)
        .background(
            isCurrent ?
                RoundedRectangle(cornerRadius: SSRadius.sm)
                    .fill(SSColors.accentSubtle.opacity(0.5)) :
                nil
        )
        .id(index)
        .contentShape(Rectangle())
        .onTapGesture {
            practiceSession.goToLine(index)
            SSHaptics.selection()
        }
    }

    private var practiceStatsBar: some View {
        HStack {
            HStack(spacing: SSSpacing.md) {
                HStack(spacing: SSSpacing.xxs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(practiceSession.formattedElapsedTime)
                }

                HStack(spacing: SSSpacing.xxs) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12))
                    Text("\(practiceSession.stumbles.count)")
                }
            }

            Spacer()

            Text("\(practiceSession.currentLineIndex + 1) / \(practiceSession.lines.count)")
                .font(.system(size: 12, design: .monospaced))
        }
        .font(SSTypography.caption)
        .foregroundStyle(SSColors.textTertiary)
        .padding(.horizontal, SSSpacing.md)
        .padding(.vertical, SSSpacing.sm)
        .background(SSColors.surface)
        .id(tick)
    }

    private var practiceControls: some View {
        HStack(spacing: SSSpacing.sm) {
            // Stumble
            Button {
                practiceSession.markStumble()
                SSHaptics.medium()
            } label: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(SSColors.recordingRed)
                    .frame(width: 52, height: 48)
                    .background(SSColors.recordingRedSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
            }

            // Next line
            Button {
                practiceSession.advanceLine()
                SSHaptics.light()
            } label: {
                HStack(spacing: SSSpacing.xxs) {
                    Text("Next")
                        .font(SSTypography.headline)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(SSColors.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(SSColors.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
            }

            // Finish
            Button {
                practiceSession.finish()
                stopTimer()
                SSHaptics.success()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SSColors.textPrimary)
                    .frame(width: 52, height: 48)
                    .background(SSColors.surfaceGlass)
                    .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
            }
        }
        .padding(.horizontal, SSSpacing.md)
        .padding(.vertical, SSSpacing.sm)
        .background(SSColors.surface)
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
