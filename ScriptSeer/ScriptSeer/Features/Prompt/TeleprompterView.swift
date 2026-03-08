import SwiftUI

struct TeleprompterView: View {
    @Environment(\.dismiss) private var dismiss
    @State var session: PromptSession
    @State private var countdownValue: Int = 3
    @State private var timer: Timer?
    @State private var showExitConfirmation = false
    @State private var speechEngine = SpeechFollowEngine()
    @State private var showSpeechControls = false
    @State private var focusConfig = FocusWindowConfig()
    @State private var currentFocusLine: Int = 0

    init(script: Script) {
        self._session = State(initialValue: PromptSession(script: script))
    }

    var body: some View {
        ZStack {
            session.theme.backgroundColor.ignoresSafeArea()

            switch session.state {
            case .idle:
                idleOverlay
            case .countdown:
                countdownOverlay
            case .prompting, .paused:
                if focusConfig.isEnabled {
                    focusWindowContent
                } else {
                    promptContent
                }
            case .completed:
                completedOverlay
            }

            // Speech follow overlay
            if speechEngine.state != .idle && speechEngine.state != .stopped {
                VStack {
                    SpeechFollowOverlay(engine: speechEngine)
                        .padding(.horizontal, SSSpacing.md)
                        .padding(.top, SSSpacing.xxl)
                    Spacer()
                }
            }

            // Floating controls
            if session.state == .prompting || session.state == .paused {
                promptControls
            }

            // Tune panel
            if session.showTuneControls {
                tunePanel
            }
        }
        .statusBarHidden(session.state == .prompting)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("Exit Prompter?", isPresented: $showExitConfirmation) {
            Button("Exit", role: .destructive) {
                stopTimer()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onDisappear { stopTimer() }
        .keyboardShortcut(.space, modifiers: [])
        .onKeyPress(.space) {
            session.togglePlayPause()
            return .handled
        }
        .onKeyPress(.upArrow) {
            session.scrollSpeed = min(session.scrollSpeed + 5, 120)
            return .handled
        }
        .onKeyPress(.downArrow) {
            session.scrollSpeed = max(session.scrollSpeed - 5, 10)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            session.jumpBack()
            return .handled
        }
        .onKeyPress(.escape) {
            showExitConfirmation = true
            return .handled
        }
    }

    // MARK: - Idle

    private var idleOverlay: some View {
        VStack(spacing: SSSpacing.lg) {
            Text(session.script.title)
                .font(SSTypography.title)
                .foregroundStyle(session.theme.textColor)

            Text("\(session.script.wordCount) words · \(session.script.formattedDuration)")
                .font(SSTypography.subheadline)
                .foregroundStyle(session.theme.textColor.opacity(0.6))

            HStack(spacing: SSSpacing.md) {
                // Display mode picker
                Menu {
                    ForEach(PromptDisplayMode.allCases, id: \.self) { mode in
                        Button(mode.rawValue) { session.displayMode = mode }
                    }
                } label: {
                    Label(session.displayMode.rawValue, systemImage: "text.alignleft")
                        .font(SSTypography.subheadline)
                        .foregroundStyle(SSColors.accent)
                        .padding(.horizontal, SSSpacing.sm)
                        .padding(.vertical, SSSpacing.xs)
                        .background(SSColors.surfaceGlass)
                        .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))
                }

                // Theme picker
                Menu {
                    ForEach(PromptTheme.allCases, id: \.self) { theme in
                        Button(theme.rawValue) { session.theme = theme }
                    }
                } label: {
                    Label("Theme", systemImage: "paintpalette")
                        .font(SSTypography.subheadline)
                        .foregroundStyle(SSColors.accent)
                        .padding(.horizontal, SSSpacing.sm)
                        .padding(.vertical, SSSpacing.xs)
                        .background(SSColors.surfaceGlass)
                        .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))
                }
            }

            Toggle("Mirrored", isOn: $session.isMirrored)
                .font(SSTypography.subheadline)
                .foregroundStyle(session.theme.textColor.opacity(0.8))
                .tint(SSColors.accent)
                .frame(width: 160)

            SSButton("Start", icon: "play.fill", variant: .primary) {
                startCountdown()
            }
            .frame(width: 200)

            Button("Back") { dismiss() }
                .foregroundStyle(session.theme.textColor.opacity(0.5))
        }
    }

    // MARK: - Countdown

    private var countdownOverlay: some View {
        VStack {
            Text("\(countdownValue)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(session.theme.textColor)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: countdownValue)
        }
    }

    // MARK: - Prompt Content

    private var promptContent: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    promptTextView(width: geometry.size.width)
                        .id("promptText")
                }
                .offset(y: -session.scrollOffset)
                .scaleEffect(x: session.isMirrored ? -1 : 1, y: 1)
                .onAppear {
                    startScrollTimer()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            session.togglePlayPause()
        }
    }

    @ViewBuilder
    private func promptTextView(width: CGFloat) -> some View {
        let margin = session.horizontalMargin
        let textWidth = width - margin * 2

        VStack(alignment: .leading, spacing: session.lineSpacing) {
            // Top padding (start with text at center)
            Spacer().frame(height: UIScreen.main.bounds.height / 2)

            switch session.displayMode {
            case .paragraph:
                Text(session.script.content)
                    .font(SSTypography.promptText(size: session.textSize))
                    .foregroundStyle(session.theme.textColor)
                    .lineSpacing(session.lineSpacing)
                    .frame(width: textWidth, alignment: .leading)

            case .oneLine, .twoLine, .chunk:
                let lines = session.script.content
                    .components(separatedBy: .newlines)
                    .flatMap { paragraph in
                        paragraph.isEmpty ? [""] : splitIntoLines(paragraph, mode: session.displayMode)
                    }

                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(SSTypography.promptText(size: session.textSize))
                        .foregroundStyle(session.theme.textColor)
                        .lineSpacing(session.lineSpacing)
                        .frame(width: textWidth, alignment: .leading)
                }
            }

            // Bottom padding
            Spacer().frame(height: UIScreen.main.bounds.height)
        }
        .padding(.horizontal, margin)
    }

    private func splitIntoLines(_ text: String, mode: PromptDisplayMode) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        let chunkSize: Int
        switch mode {
        case .oneLine: chunkSize = 4
        case .twoLine: chunkSize = 8
        case .chunk: chunkSize = 12
        case .paragraph: return [text]
        }
        return stride(from: 0, to: words.count, by: chunkSize).map { start in
            let end = min(start + chunkSize, words.count)
            return words[start..<end].joined(separator: " ")
        }
    }

    // MARK: - Focus Window

    private var focusWindowContent: some View {
        let allLines = splitScriptIntoChunks(
            session.script.content,
            wordsPerChunk: focusConfig.preset.wordsPerChunk
        )

        return FocusWindowView(
            lines: allLines,
            currentLineIndex: currentFocusLine,
            config: focusConfig,
            theme: session.theme,
            textSize: session.textSize
        )
        .contentShape(Rectangle())
        .onTapGesture {
            session.togglePlayPause()
        }
        .onAppear { startFocusTimer() }
        .scaleEffect(x: session.isMirrored ? -1 : 1, y: 1)
    }

    private func splitScriptIntoChunks(_ text: String, wordsPerChunk: Int) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        return stride(from: 0, to: words.count, by: wordsPerChunk).map { start in
            let end = min(start + wordsPerChunk, words.count)
            return words[start..<end].joined(separator: " ")
        }
    }

    private func startFocusTimer() {
        // Advance focus line based on scroll speed
        let totalLines = splitScriptIntoChunks(
            session.script.content,
            wordsPerChunk: focusConfig.preset.wordsPerChunk
        ).count
        guard totalLines > 0 else { return }

        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { timer in
            guard session.state == .prompting else { return }
            if self.currentFocusLine >= totalLines - 1 {
                timer.invalidate()
                session.complete()
                return
            }
            // Advance roughly based on speed: higher speed = faster line changes
            let advanceInterval = max(60.0 / session.scrollSpeed, 0.5)
            let framesSinceStart = session.scrollOffset / (session.scrollSpeed / 30.0)
            let targetLine = Int(framesSinceStart / (advanceInterval * 30.0))
            self.currentFocusLine = min(targetLine, totalLines - 1)
        }
    }

    // MARK: - Controls

    private var promptControls: some View {
        VStack {
            Spacer()
            HStack(spacing: SSSpacing.lg) {
                // Jump back
                ControlButton(icon: "gobackward") {
                    session.jumpBack()
                    SSHaptics.light()
                }

                // Play / Pause
                ControlButton(icon: session.state == .prompting ? "pause.fill" : "play.fill") {
                    session.togglePlayPause()
                    SSHaptics.light()
                }

                // Speech follow
                ControlButton(icon: speechEngine.state == .idle || speechEngine.state == .stopped ? "waveform" : "waveform.badge.minus") {
                    toggleSpeechFollow()
                }

                // Tune
                ControlButton(icon: "slider.horizontal.3") {
                    withAnimation(SSAnimation.standard) {
                        session.showTuneControls.toggle()
                    }
                    SSHaptics.selection()
                }

                // Exit
                ControlButton(icon: "xmark") {
                    showExitConfirmation = true
                }
            }
            .padding(.vertical, SSSpacing.sm)
            .padding(.horizontal, SSSpacing.lg)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.full))
            .padding(.bottom, SSSpacing.lg)
        }
    }

    // MARK: - Tune Panel

    private var tunePanel: some View {
        VStack {
            Spacer()

            VStack(spacing: SSSpacing.md) {
                Text("Tune")
                    .font(SSTypography.headline)
                    .foregroundStyle(SSColors.textPrimary)

                TuneSlider(label: "Speed", value: $session.scrollSpeed, range: 10...120, unit: "pt/s")
                TuneSlider(label: "Text Size", value: $session.textSize, range: 18...72, unit: "pt")
                TuneSlider(label: "Line Spacing", value: $session.lineSpacing, range: 4...40, unit: "pt")
                TuneSlider(label: "Margins", value: $session.horizontalMargin, range: 8...80, unit: "pt")

                HStack {
                    Picker("Display", selection: $session.displayMode) {
                        ForEach(PromptDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Divider().background(SSColors.divider)

                Toggle("Focus Window", isOn: $focusConfig.isEnabled)
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textPrimary)
                    .tint(SSColors.accent)

                if focusConfig.isEnabled {
                    TuneSlider(label: "Vertical Offset", value: $focusConfig.verticalOffset, range: 0.05...0.8, unit: "")

                    GlancePresetPicker(selectedPreset: $focusConfig.preset) { preset in
                        session.textSize = preset.textSize
                        session.horizontalMargin = preset.horizontalMargin
                        session.lineSpacing = preset.lineSpacing
                    }
                }

                Button("Done") {
                    withAnimation(SSAnimation.standard) {
                        session.showTuneControls = false
                    }
                }
                .foregroundStyle(SSColors.accent)
            }
            .padding(SSSpacing.lg)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.xl))
            .padding(.horizontal, SSSpacing.md)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Completed

    private var completedOverlay: some View {
        VStack(spacing: SSSpacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(SSColors.accent)

            Text("Done!")
                .font(SSTypography.title)
                .foregroundStyle(session.theme.textColor)

            SSButton("Exit", variant: .secondary) { dismiss() }
                .frame(width: 160)
        }
    }

    // MARK: - Timer

    private func startCountdown() {
        countdownValue = session.countdownSeconds
        session.state = .countdown
        SSHaptics.medium()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdownValue > 1 {
                countdownValue -= 1
                SSHaptics.light()
            } else {
                timer?.invalidate()
                timer = nil
                session.scrollOffset = 0
                session.play()
            }
        }
    }

    private func startScrollTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard session.state == .prompting else { return }
            session.scrollOffset += session.scrollSpeed / 60.0
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Speech Follow

    private func toggleSpeechFollow() {
        if speechEngine.state == .idle || speechEngine.state == .stopped {
            speechEngine.prepare(scriptContent: session.script.content)
            Task {
                let authorized = await speechEngine.requestAuthorization()
                if authorized {
                    speechEngine.start()
                    SSHaptics.success()
                } else {
                    SSHaptics.error()
                }
            }
        } else {
            speechEngine.stop()
            SSHaptics.light()
        }
    }
}

// MARK: - Sub-components

private struct ControlButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
        }
    }
}

private struct TuneSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    init(label: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) {
        self.label = label
        self._value = value
        self.range = range
        self.unit = unit
    }

    init(label: String, value: Binding<CGFloat>, range: ClosedRange<Double>, unit: String) {
        self.label = label
        self._value = Binding(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = CGFloat($0) }
        )
        self.range = range
        self.unit = unit
    }

    var body: some View {
        VStack(spacing: SSSpacing.xxs) {
            HStack {
                Text(label)
                    .font(SSTypography.caption)
                    .foregroundStyle(SSColors.textSecondary)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(SSTypography.caption)
                    .foregroundStyle(SSColors.textTertiary)
            }
            Slider(value: $value, in: range)
                .tint(SSColors.accent)
        }
    }
}
