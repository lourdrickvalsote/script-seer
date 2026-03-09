import SwiftUI
import SwiftData

struct PracticeSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State var practiceSession: PracticeSession
    @State private var timer: Timer?
    @State private var tick: Int = 0
    @State private var speechEngine = SpeechFollowEngine()
    @State private var useSpeechFollow = false
    @State private var showSpeechPermissionDenied = false
    @State private var lastWordIndex: Int = -1
    @State private var stallTimer: Timer?
    @State private var autoStumbleFlashLine: Int? = nil
    @State private var remoteInput = RemoteInputService.shared

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
        .alert("Speech Recognition Unavailable", isPresented: $showSpeechPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("ScriptSeer needs speech recognition permission for Smart Follow. Please enable it in Settings.")
        }
        .onDisappear {
            stopTimer()
            stopSpeechFollow()
        }
        .onChange(of: speechEngine.currentWordIndex) { _, newWordIndex in
            handleWordAdvance(newWordIndex)
        }
        .onChange(of: speechEngine.state) { oldState, newState in
            handleSpeechStateChange(from: oldState, to: newState)
        }
        .onChange(of: remoteInput.latestAction?.id) {
            guard practiceSession.isActive,
                  let (action, _) = remoteInput.latestAction else { return }
            switch action {
            case .playPause, .nextLine:
                if isLastLine {
                    practiceSession.finish()
                    savePracticeRecord()
                    stopTimer()
                    stopSpeechFollow()
                    SSHaptics.success()
                } else {
                    practiceSession.advanceLine()
                    SSHaptics.light()
                }
            case .markStumble:
                practiceSession.markStumble()
                SSHaptics.medium()
            case .jumpBack:
                if practiceSession.currentLineIndex > 0 {
                    practiceSession.currentLineIndex -= 1
                }
            default: break
            }
        }
        .onKeyPress(.space) {
            guard practiceSession.isActive else { return .ignored }
            if isLastLine {
                practiceSession.finish()
                savePracticeRecord()
                stopTimer()
                stopSpeechFollow()
                SSHaptics.success()
            } else {
                practiceSession.advanceLine()
                SSHaptics.light()
            }
            return .handled
        }
        .onKeyPress(.return) {
            guard practiceSession.isActive else { return .ignored }
            if isLastLine {
                practiceSession.finish()
                savePracticeRecord()
                stopTimer()
                stopSpeechFollow()
                SSHaptics.success()
            } else {
                practiceSession.advanceLine()
                SSHaptics.light()
            }
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "sS")) { _ in
            guard practiceSession.isActive else { return .ignored }
            practiceSession.markStumble()
            SSHaptics.medium()
            return .handled
        }
        .onKeyPress(.upArrow) {
            guard practiceSession.isActive, practiceSession.currentLineIndex > 0 else { return .ignored }
            practiceSession.currentLineIndex -= 1
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard practiceSession.isActive else { return .ignored }
            if isLastLine {
                practiceSession.finish()
                savePracticeRecord()
                stopTimer()
                stopSpeechFollow()
                SSHaptics.success()
            } else {
                practiceSession.advanceLine()
                SSHaptics.light()
            }
            return .handled
        }
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

                // Smart Follow toggle
                VStack(spacing: SSSpacing.xs) {
                    Toggle(isOn: $useSpeechFollow) {
                        HStack(spacing: SSSpacing.xs) {
                            Image(systemName: "waveform")
                                .font(.system(size: 14))
                                .foregroundStyle(SSColors.accent)
                            Text("Smart Follow")
                                .font(SSTypography.subheadline)
                                .foregroundStyle(SSColors.textPrimary)
                        }
                    }
                    .tint(SSColors.accent)

                    if useSpeechFollow {
                        Text("Uses your microphone to track progress\nand detect stumbles automatically.")
                            .font(SSTypography.caption)
                            .foregroundStyle(SSColors.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }
                .padding(.horizontal, SSSpacing.lg)
                .padding(.vertical, SSSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SSRadius.lg)
                        .fill(SSColors.surfaceElevated)
                )
                .padding(.horizontal, SSSpacing.xl)
            }

            Spacer()

            VStack(spacing: SSSpacing.md) {
                Button {
                    practiceSession.start()
                    if useSpeechFollow {
                        practiceSession.usedSpeechFollow = true
                        startSpeechFollow()
                    }
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

            // Speech follow pill
            if useSpeechFollow && speechEngine.state != .idle && speechEngine.state != .stopped {
                SpeechFollowOverlay(engine: speechEngine)
                    .padding(.top, SSSpacing.xs)
            }

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
        let isFlashing = autoStumbleFlashLine == index

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

            Group {
                if isCurrent && useSpeechFollow {
                    let wordOffset = practiceSession.lineWordRanges[index].start
                    highlightedText(
                        content: line,
                        globalWordIndex: speechEngine.currentWordIndex,
                        globalWordOffset: wordOffset,
                        currentColor: SSColors.textPrimary,
                        pastColor: SSColors.textTertiary,
                        futureColor: SSColors.textSecondary,
                        fontSize: 17,
                        fontWeight: .regular
                    )
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
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
            }
        }
        .padding(.vertical, SSSpacing.xxs)
        .padding(.horizontal, SSSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: SSRadius.sm)
                .fill(
                    isFlashing ? SSColors.recordingRedSubtle :
                    isCurrent ? SSColors.accentSubtle.opacity(0.5) :
                    Color.clear
                )
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

                if useSpeechFollow && speechEngine.speakingWPM > 0 {
                    HStack(spacing: SSSpacing.xxs) {
                        Image(systemName: "waveform")
                            .font(.system(size: 12))
                        Text("\(Int(speechEngine.speakingWPM)) wpm")
                    }
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

    private var isLastLine: Bool {
        practiceSession.currentLineIndex >= practiceSession.lines.count - 1
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

            if isLastLine {
                // Finish (replaces Next + Done on last line)
                Button {
                    practiceSession.finish()
                    savePracticeRecord()
                    stopTimer()
                    stopSpeechFollow()
                    SSHaptics.success()
                } label: {
                    HStack(spacing: SSSpacing.xxs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("Finish")
                            .font(SSTypography.headline)
                    }
                    .foregroundStyle(SSColors.lavenderMist)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: SSRadius.md)
                            .fill(
                                LinearGradient(
                                    colors: [SSColors.accent, SSColors.accent.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
            } else {
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

                // Done
                Button {
                    practiceSession.finish()
                    savePracticeRecord()
                    stopTimer()
                    stopSpeechFollow()
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
        if useSpeechFollow {
            stopSpeechFollow()
            startSpeechFollow()
        }
        stopTimer()
        startTimer()
    }

    // MARK: - Speech Follow

    private func startSpeechFollow() {
        let savedMode = UserDefaults.standard.string(forKey: "speechFollowMode") ?? "Smart"
        speechEngine.mode = SpeechFollowMode(rawValue: savedMode) ?? .smart
        speechEngine.applyStoredLanguageSetting()
        speechEngine.prepare(scriptContent: practiceSession.content)
        Task {
            let authorized = await speechEngine.requestAuthorization()
            if authorized {
                speechEngine.start()
                startStallDetection()
            } else {
                showSpeechPermissionDenied = true
                useSpeechFollow = false
            }
        }
    }

    private func stopSpeechFollow() {
        stallTimer?.invalidate()
        stallTimer = nil
        if speechEngine.state != .idle && speechEngine.state != .stopped {
            speechEngine.stop()
        }
    }

    private func savePracticeRecord() {
        practiceSession.script.lastPracticedAt = Date()
        let record = PracticeRecord(
            date: practiceSession.startTime ?? Date(),
            duration: practiceSession.elapsedTime,
            wordsPerMinute: practiceSession.wordsPerMinute,
            stumbleCount: practiceSession.stumbles.count,
            usedSpeechFollow: practiceSession.usedSpeechFollow,
            script: practiceSession.script
        )
        modelContext.insert(record)
    }

    private func handleWordAdvance(_ newWordIndex: Int) {
        guard useSpeechFollow, practiceSession.isActive else { return }

        // Map word index to line index and auto-advance
        if let lineIdx = practiceSession.lineIndex(forWordIndex: newWordIndex),
           lineIdx != practiceSession.currentLineIndex {
            practiceSession.goToLine(lineIdx)
        }

        // Reset stall timer on word advance
        lastWordIndex = newWordIndex
        resetStallTimer()
    }

    private func handleSpeechStateChange(from oldState: SpeechFollowState, to newState: SpeechFollowState) {
        guard useSpeechFollow, practiceSession.isActive else { return }

        if newState == .lowConfidence && oldState == .following {
            // Start a 2-second timer for low confidence stumble
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if speechEngine.state == .lowConfidence {
                    triggerAutoStumble()
                }
            }
        }
    }

    private func startStallDetection() {
        lastWordIndex = speechEngine.currentWordIndex
        resetStallTimer()
    }

    private func resetStallTimer() {
        stallTimer?.invalidate()
        stallTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            guard useSpeechFollow, practiceSession.isActive else {
                stallTimer?.invalidate()
                stallTimer = nil
                return
            }
            let baseline = lastWordIndex
            if speechEngine.currentWordIndex == baseline &&
               (speechEngine.state == .following || speechEngine.state == .lowConfidence) {
                triggerAutoStumble()
            }
            lastWordIndex = speechEngine.currentWordIndex
        }
    }

    private func triggerAutoStumble() {
        let line = practiceSession.currentLineIndex
        practiceSession.autoMarkStumble(atLine: line)
        SSHaptics.medium()

        // Flash the line red briefly
        withAnimation(SSAnimation.standard) {
            autoStumbleFlashLine = line
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(SSAnimation.standard) {
                autoStumbleFlashLine = nil
            }
        }
    }
}
