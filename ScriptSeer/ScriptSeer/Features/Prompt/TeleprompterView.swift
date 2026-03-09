import SwiftUI

struct TeleprompterView: View {
    @Environment(\.dismiss) private var dismiss
    @State var session: PromptSession
    @State private var countdownValue: Int = 3
    @State private var timer: Timer?
    @State private var showExitConfirmation = false
    @State private var speechEngine = SpeechFollowEngine()
    @State private var showSpeechControls = false
    @State private var showSpeechPermissionDenied = false
    @State private var focusConfig = FocusWindowConfig()
    @State private var currentFocusLine: Int = 0
    @State private var showScrubBar = false
    @State private var externalDisplay = ExternalDisplayManager()
    @State private var gameController = GameControllerManager()

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

            // Speech follow pill (top-center)
            if speechEngine.state != .idle && speechEngine.state != .stopped {
                VStack {
                    SpeechFollowOverlay(engine: speechEngine)
                        .padding(.top, SSSpacing.xl)
                    Spacer()
                }
            }

            // Floating controls
            if session.state == .prompting || session.state == .paused {
                promptControls
            }

            // Tune panel (full-screen sheet)
            if session.showTuneControls {
                tunePanel
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .preference(key: HideRecordButtonKey.self, value: true)
        .statusBarHidden(session.state == .prompting)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("Exit Prompter?", isPresented: $showExitConfirmation) {
            Button("Exit", role: .destructive) {
                stopTimer()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Speech Recognition Unavailable", isPresented: $showSpeechPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("ScriptSeer needs speech recognition permission for hands-free script following. Please enable it in Settings.")
        }
        .onDisappear { stopTimer() }
        .onAppear {
            gameController.onPlayPause = { session.togglePlayPause() }
            gameController.onJumpBack = { session.jumpBack() }
            gameController.onJumpForward = { session.jumpForward() }
            gameController.onSpeedUp = { session.scrollSpeed = min(session.scrollSpeed + 5, 120) }
            gameController.onSpeedDown = { session.scrollSpeed = max(session.scrollSpeed - 5, 10) }
        }
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
        .onKeyPress(.rightArrow) {
            session.jumpForward()
            return .handled
        }
        .onKeyPress(.escape) {
            showExitConfirmation = true
            return .handled
        }
    }

    // MARK: - Idle

    private var idleOverlay: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title + metadata
            VStack(spacing: SSSpacing.sm) {
                Text(session.script.title)
                    .font(SSTypography.largeTitle)
                    .foregroundStyle(session.theme.textColor)
                    .multilineTextAlignment(.center)

                Text("\(session.script.wordCount) words · \(session.script.formattedDuration)")
                    .font(SSTypography.footnote)
                    .foregroundStyle(session.theme.textColor.opacity(0.5))
            }

            Spacer().frame(height: SSSpacing.xxl)

            // Settings card
            VStack(spacing: 0) {
                // Display mode
                idleSettingRow(label: "Display") {
                    Menu {
                        ForEach(PromptDisplayMode.allCases, id: \.self) { mode in
                            Button(mode.rawValue) { session.displayMode = mode }
                        }
                    } label: {
                        HStack(spacing: SSSpacing.xxs) {
                            Text(session.displayMode.rawValue)
                                .font(SSTypography.subheadline)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(SSColors.accent)
                    }
                }

                idleDivider

                // Theme
                idleSettingRow(label: "Theme") {
                    Menu {
                        ForEach(PromptTheme.allCases, id: \.self) { theme in
                            Button(theme.rawValue) { session.theme = theme }
                        }
                    } label: {
                        HStack(spacing: SSSpacing.xxs) {
                            Text(session.theme.rawValue)
                                .font(SSTypography.subheadline)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(SSColors.accent)
                    }
                }

                idleDivider

                // Mirror toggle
                idleSettingRow(label: "Mirrored") {
                    Toggle("", isOn: $session.isMirrored)
                        .labelsHidden()
                        .tint(SSColors.accent)
                }

                idleDivider

                // Rig mode
                idleSettingRow(label: "Rig Mode") {
                    Toggle("", isOn: Binding(
                        get: { session.rigModeEnabled },
                        set: { enabled in
                            session.rigModeEnabled = enabled
                            if enabled {
                                session.isMirrored = true
                                session.theme = .lightOnDark
                                session.textSize = SSLayout.isIPad ? 56 : 42
                                session.horizontalMargin = SSLayout.isIPad ? 60 : 24
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(SSColors.accent)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: SSRadius.lg)
                    .fill(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.lg))
            .padding(.horizontal, SSSpacing.xl)

            Spacer()

            // Bottom actions
            VStack(spacing: SSSpacing.md) {
                Button(action: { startCountdown() }) {
                    HStack(spacing: SSSpacing.xs) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Begin Reading")
                            .font(SSTypography.headline)
                    }
                    .foregroundStyle(.white)
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
                            .shadow(color: SSColors.accent.opacity(0.4), radius: 16, x: 0, y: 6)
                    )
                }
                .buttonStyle(.plain)

                Button("Back") { dismiss() }
                    .font(SSTypography.subheadline)
                    .foregroundStyle(session.theme.textColor.opacity(0.4))
            }
            .padding(.horizontal, SSSpacing.xl)
            .padding(.bottom, SSSpacing.xxl)
        }
    }

    private func idleSettingRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(SSTypography.subheadline)
                .foregroundStyle(session.theme.textColor.opacity(0.7))
            Spacer()
            content()
        }
        .padding(.horizontal, SSSpacing.lg)
        .padding(.vertical, SSSpacing.sm)
    }

    private var idleDivider: some View {
        Divider()
            .background(session.theme.textColor.opacity(0.1))
            .padding(.horizontal, SSSpacing.md)
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
            ScrollView(.vertical, showsIndicators: false) {
                promptTextView(width: geometry.size.width, height: geometry.size.height)
                    .id("promptText")
            }
            .offset(y: -session.scrollOffset)
            .scaleEffect(x: session.isMirrored ? -1 : 1, y: 1)
            .onAppear {
                startScrollTimer()
            }
            .onChange(of: session.measuredContentHeight) { _, height in
                if height > 0 && session.state == .prompting && timer == nil {
                    startScrollTimer()
                }
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture {
            session.togglePlayPause()
        }
    }

    @ViewBuilder
    private func promptTextView(width: CGFloat, height: CGFloat) -> some View {
        let margin = session.horizontalMargin

        VStack(alignment: .leading, spacing: session.lineSpacing) {
            // Top padding (start with text at center)
            Spacer().frame(height: height / 2)

            switch session.displayMode {
            case .paragraph:
                if session.hookModeEnabled {
                    let paragraphs = session.script.content
                        .components(separatedBy: .newlines)
                        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, para in
                        let isHook = index < session.hookLineCount
                        richPromptText(para, sizeOverride: isHook ? session.textSize * 1.3 : nil)
                            .lineSpacing(session.lineSpacing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .opacity(isHook ? 1.0 : 0.85)
                    }
                } else {
                    richPromptText(session.script.content)
                        .lineSpacing(session.lineSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

            case .oneLine, .twoLine, .chunk:
                let lines = CueParser.stripCues(session.script.content)
                    .components(separatedBy: .newlines)
                    .flatMap { paragraph in
                        paragraph.isEmpty ? [""] : splitIntoLines(paragraph, mode: session.displayMode)
                    }

                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    let isHook = session.hookModeEnabled && index < session.hookLineCount
                    Text(line)
                        .font(SSTypography.promptText(size: isHook ? session.textSize * 1.3 : session.textSize))
                        .foregroundStyle(session.theme.textColor)
                        .lineSpacing(session.lineSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(isHook ? 1.0 : 0.85)
                }
            }

            // Bottom padding
            Spacer().frame(height: height)
        }
        .padding(.horizontal, margin)
        .frame(width: width)
        .background(
            GeometryReader { contentGeometry in
                Color.clear
                    .onAppear {
                        session.measuredContentHeight = contentGeometry.size.height
                    }
                    .onChange(of: contentGeometry.size.height) { _, newHeight in
                        session.measuredContentHeight = newHeight
                    }
            }
        )
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

    /// Renders script content with cue markers, speaker labels, and section dividers
    private func richPromptText(_ content: String, sizeOverride: CGFloat? = nil) -> Text {
        let size = sizeOverride ?? session.textSize
        let segments = CueParser.parse(content)
        var result = Text("")
        for segment in segments {
            switch segment.kind {
            case .cue(let cue):
                result = result + Text(" \(cue.displaySymbol) ")
                    .font(.system(size: size * 0.7))
                    .foregroundColor(cue.promptColor)
            case .speaker(let name):
                result = result + Text("\n\(name.uppercased()): ")
                    .font(.system(size: size * 0.8, weight: .bold))
                    .foregroundColor(SSColors.accent)
            case .section(let title):
                result = result + Text("\n— \(title) —\n")
                    .font(.system(size: size * 0.75, weight: .semibold))
                    .foregroundColor(SSColors.silverSage)
            case .text:
                result = result + Text(segment.content)
                    .font(SSTypography.promptText(size: size))
                    .foregroundColor(session.theme.textColor)
            }
        }
        return result
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
        let chunkSize = max(1, wordsPerChunk)
        let words = text.split(separator: " ").map(String.init)
        return stride(from: 0, to: words.count, by: chunkSize).map { start in
            let end = min(start + chunkSize, words.count)
            return words[start..<end].joined(separator: " ")
        }
    }

    private func startFocusTimer() {
        stopTimer()
        let totalLines = splitScriptIntoChunks(
            session.script.content,
            wordsPerChunk: focusConfig.preset.wordsPerChunk
        ).count
        guard totalLines > 0 else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            guard session.state == .prompting else { return }
            if self.currentFocusLine >= totalLines - 1 {
                self.stopTimer()
                SSHaptics.success()
                session.complete()
                return
            }
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

            VStack(spacing: SSSpacing.sm) {
                // Scrub bar (toggleable)
                if showScrubBar {
                    scrubBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Main control bar
                HStack(spacing: 0) {
                    // Jump back
                    PromptControlButton(icon: "backward.fill", size: 16) {
                        session.jumpBack()
                        SSHaptics.light()
                    }

                    // Play / Pause — larger, center
                    PromptControlButton(
                        icon: session.state == .prompting ? "pause.fill" : "play.fill",
                        size: 22,
                        isAccented: true
                    ) {
                        session.togglePlayPause()
                        SSHaptics.light()
                    }

                    // Jump forward
                    PromptControlButton(icon: "forward.fill", size: 16) {
                        session.jumpForward()
                        SSHaptics.light()
                    }

                    // Divider
                    controlDivider

                    // Scrub toggle
                    PromptControlButton(
                        icon: "text.line.first.and.arrowtriangle.forward",
                        size: 16,
                        isActive: showScrubBar
                    ) {
                        withAnimation(SSAnimation.standard) {
                            showScrubBar.toggle()
                        }
                        SSHaptics.selection()
                    }

                    // Speech follow
                    PromptControlButton(
                        icon: "waveform",
                        size: 16,
                        isActive: speechEngine.state != .idle && speechEngine.state != .stopped
                    ) {
                        toggleSpeechFollow()
                    }

                    // Tune
                    PromptControlButton(icon: "slider.horizontal.3", size: 16) {
                        withAnimation(SSAnimation.standard) {
                            session.showTuneControls.toggle()
                        }
                        SSHaptics.selection()
                    }

                    // Divider
                    controlDivider

                    // Exit
                    PromptControlButton(icon: "xmark", size: 14) {
                        showExitConfirmation = true
                    }
                }
                .padding(.horizontal, SSSpacing.xs)
                .padding(.vertical, SSSpacing.xxs)
                .background(.ultraThinMaterial)
                .background(.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: SSRadius.lg))
                .padding(.horizontal, SSSpacing.lg)
            }
            .padding(.bottom, SSSpacing.lg)
        }
    }

    private var controlDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.12))
            .frame(width: 1, height: 24)
            .padding(.horizontal, SSSpacing.xxs)
    }

    private var scrubBar: some View {
        VStack(spacing: SSSpacing.xs) {
            // Section chips
            if !session.sections.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SSSpacing.xxs) {
                        ForEach(Array(session.sections.enumerated()), id: \.offset) { _, section in
                            Button {
                                session.scrollProgress = section.progress
                                SSHaptics.light()
                            } label: {
                                Text(section.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineLimit(1)
                                    .padding(.horizontal, SSSpacing.xs)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, SSSpacing.sm)
                }
            }

            // Progress slider
            HStack(spacing: SSSpacing.sm) {
                Text("\(Int(session.scrollProgress * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 32, alignment: .trailing)

                Slider(
                    value: Binding(
                        get: { session.scrollProgress },
                        set: { session.scrollProgress = $0 }
                    ),
                    in: 0...1
                )
                .tint(.white.opacity(0.5))
            }
            .padding(.horizontal, SSSpacing.md)
        }
        .padding(.vertical, SSSpacing.sm)
        .background(.ultraThinMaterial)
        .background(.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: SSRadius.lg))
        .padding(.horizontal, SSSpacing.lg)
    }

    // MARK: - Tune Panel

    private var tunePanel: some View {
        ZStack {
            // Dimming background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(SSAnimation.standard) {
                        session.showTuneControls = false
                    }
                }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(SSTypography.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            withAnimation(SSAnimation.standard) {
                                session.showTuneControls = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(width: 32, height: 32)
                                .background(.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, SSSpacing.lg)
                    .padding(.top, SSSpacing.lg)
                    .padding(.bottom, SSSpacing.md)

                    // Scrollable settings
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: SSSpacing.lg) {
                            // Scroll section
                            tuneSection("Scroll") {
                                Picker("Scroll Mode", selection: $session.scrollMode) {
                                    ForEach(ScrollMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if session.scrollMode == .manual {
                                    TuneSlider(label: "Speed", value: $session.scrollSpeed, range: 10...120, unit: " pt/s")
                                } else {
                                    TuneSlider(label: "Duration", value: $session.targetDurationMinutes, range: 0.5...30, unit: " min")
                                    HStack {
                                        Text("Auto speed")
                                            .font(SSTypography.caption)
                                            .foregroundStyle(.white.opacity(0.4))
                                        Spacer()
                                        Text("\(Int(session.timedScrollSpeed)) pt/s")
                                            .font(SSTypography.caption)
                                            .foregroundStyle(.white.opacity(0.3))
                                    }
                                }
                            }

                            // Typography section
                            tuneSection("Typography") {
                                TuneSlider(label: "Text Size", value: $session.textSize, range: 18...72, unit: " pt")
                                TuneSlider(label: "Line Spacing", value: $session.lineSpacing, range: 4...40, unit: " pt")
                                TuneSlider(label: "Margins", value: $session.horizontalMargin, range: 8...80, unit: " pt")

                                Picker("Display", selection: $session.displayMode) {
                                    ForEach(PromptDisplayMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            // Speech section
                            tuneSection("Speech") {
                                Toggle("Confidence Scroll", isOn: $speechEngine.isConfidenceScrollEnabled)
                                    .font(SSTypography.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                                    .tint(SSColors.accent)

                                if speechEngine.isConfidenceScrollEnabled {
                                    HStack {
                                        Text("Speaking pace")
                                            .font(SSTypography.caption)
                                            .foregroundStyle(.white.opacity(0.4))
                                        Spacer()
                                        Text("\(Int(speechEngine.speakingWPM)) wpm → \(Int(speechEngine.adaptiveSpeed)) pt/s")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(.white.opacity(0.3))
                                    }
                                }
                            }

                            // Focus section
                            tuneSection("Focus") {
                                Toggle("Focus Window", isOn: $focusConfig.isEnabled)
                                    .font(SSTypography.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                                    .tint(SSColors.accent)

                                if focusConfig.isEnabled {
                                    TuneSlider(label: "Vertical Offset", value: $focusConfig.verticalOffset, range: 0.05...0.8, unit: "")

                                    GlancePresetPicker(selectedPreset: $focusConfig.preset) { preset in
                                        session.textSize = preset.textSize
                                        session.horizontalMargin = preset.horizontalMargin
                                        session.lineSpacing = preset.lineSpacing
                                    }
                                }
                            }

                            // Advanced section
                            tuneSection("Advanced") {
                                Toggle("Hook Mode", isOn: $session.hookModeEnabled)
                                    .font(SSTypography.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                                    .tint(SSColors.accent)

                                if session.hookModeEnabled {
                                    Text("First \(session.hookLineCount) lines get 30% larger text")
                                        .font(SSTypography.caption)
                                        .foregroundStyle(.white.opacity(0.4))
                                }

                                if externalDisplay.isExternalDisplayConnected {
                                    HStack(spacing: SSSpacing.xs) {
                                        Image(systemName: "tv.fill")
                                            .foregroundStyle(SSColors.accent)
                                        Text("External Display Connected")
                                            .font(SSTypography.subheadline)
                                            .foregroundStyle(.white.opacity(0.85))
                                    }
                                }

                                if gameController.isControllerConnected {
                                    HStack(spacing: SSSpacing.xs) {
                                        Image(systemName: "gamecontroller.fill")
                                            .foregroundStyle(SSColors.accent)
                                        Text(gameController.controllerName)
                                            .font(SSTypography.subheadline)
                                            .foregroundStyle(.white.opacity(0.85))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, SSSpacing.lg)
                        .padding(.bottom, SSSpacing.xxl)
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                .background(.ultraThinMaterial)
                .background(.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: SSRadius.xl))
                .padding(.horizontal, SSSpacing.sm)
                .padding(.bottom, SSSpacing.sm)
            }
        }
        .transition(.opacity)
    }

    private func tuneSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: SSSpacing.sm) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(1)

            content()
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

            // Session stats
            HStack(spacing: SSSpacing.xl) {
                VStack(spacing: SSSpacing.xxs) {
                    Text(session.formattedElapsed)
                        .font(SSTypography.headline)
                        .foregroundStyle(session.theme.textColor)
                    Text("Duration")
                        .font(SSTypography.caption)
                        .foregroundStyle(session.theme.textColor.opacity(0.6))
                }
                VStack(spacing: SSSpacing.xxs) {
                    Text("\(session.script.wordCount)")
                        .font(SSTypography.headline)
                        .foregroundStyle(session.theme.textColor)
                    Text("Words")
                        .font(SSTypography.caption)
                        .foregroundStyle(session.theme.textColor.opacity(0.6))
                }
                if session.completionWPM > 0 {
                    VStack(spacing: SSSpacing.xxs) {
                        Text("\(session.completionWPM)")
                            .font(SSTypography.headline)
                            .foregroundStyle(session.theme.textColor)
                        Text("WPM")
                            .font(SSTypography.caption)
                            .foregroundStyle(session.theme.textColor.opacity(0.6))
                    }
                }
            }

            HStack(spacing: SSSpacing.md) {
                SSButton("Restart", icon: "arrow.counterclockwise", variant: .secondary) {
                    session.scrollOffset = 0
                    session.state = .idle
                }
                .frame(width: 150)

                SSButton("Exit", variant: .secondary) { dismiss() }
                    .frame(width: 120)
            }
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
        guard session.measuredContentHeight > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard session.state == .prompting else { return }
            let speed = speechEngine.isConfidenceScrollEnabled ? speechEngine.adaptiveSpeed : session.effectiveScrollSpeed
            session.scrollOffset += speed / 60.0

            // Auto-complete when scrolled past content
            if session.measuredContentHeight > 0, session.scrollOffset >= session.measuredContentHeight {
                self.stopTimer()
                SSHaptics.success()
                session.complete()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Speech Follow

    private func toggleSpeechFollow() {
        if speechEngine.state == .idle || speechEngine.state == .stopped {
            // Apply user's preferred speech follow mode
            let savedMode = UserDefaults.standard.string(forKey: "speechFollowMode") ?? "Smart"
            speechEngine.mode = SpeechFollowMode(rawValue: savedMode) ?? .smart
            speechEngine.prepare(scriptContent: session.script.content)
            Task {
                let authorized = await speechEngine.requestAuthorization()
                if authorized {
                    speechEngine.resetPaceTracking(baseSpeed: session.scrollSpeed)
                    speechEngine.start()
                    SSHaptics.success()
                } else {
                    showSpeechPermissionDenied = true
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

private struct PromptControlButton: View {
    let icon: String
    var size: CGFloat = 18
    var isAccented: Bool = false
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(isAccented ? SSColors.accent : isActive ? SSColors.accent : .white.opacity(0.8))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(icon)
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
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
            Slider(value: $value, in: range)
                .tint(SSColors.accent)
        }
    }
}
