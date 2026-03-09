import SwiftUI
import AVFoundation

private enum RecordFollowMode: String, CaseIterable {
    case speechSmart = "Smart Follow"
    case speechStrict = "Strict Follow"
    case manualScroll = "Manual Scroll"
}

struct CameraRecordView: View {
    @Environment(\.dismiss) private var dismiss
    let script: Script
    let contentOverride: String?
    @State private var cameraService = CameraService()
    @State private var promptSession: PromptSession
    @State private var speechEngine = SpeechFollowEngine()
    @State private var followMode: RecordFollowMode = .speechSmart
    @State private var countdownValue = 3
    @State private var showCountdown = false
    @State private var countdownTimer: Timer?
    @State private var scrollTimer: Timer?
    @State private var recordingStartTime: Date?
    @State private var recordingDuration: TimeInterval = 0
    @State private var durationTimer: Timer?
    @State private var showExitConfirmation = false
    @State private var showShareSheet = false
    @State private var showSettings = false
    @State private var cameraPermissionDenied = false
    @State private var micPermissionDenied = false
    @State private var recordingDotVisible = true
    @State private var countdownScale: CGFloat = 1.5
    @State private var countdownOpacity: Double = 1.0
    @State private var countdownProgress: CGFloat = 1.0
    @State private var takeSavedAppeared = false
    @State private var speechSentenceIndex: Int = 0
    @State private var smoothScrollY: CGFloat = 0
    @State private var sentenceHeights: [Int: CGFloat] = [:]
    @State private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation

    private enum LayoutMode {
        case portrait
        case landscapeLeft   // Dynamic Island on left side of screen
        case landscapeRight  // Dynamic Island on right side of screen
    }

    private var layoutMode: LayoutMode {
        switch deviceOrientation {
        case .landscapeLeft: .landscapeLeft
        case .landscapeRight: .landscapeRight
        default: .portrait
        }
    }

    private var isLandscape: Bool {
        layoutMode != .portrait
    }

    private var isRecording: Bool {
        cameraService.recordingState == .recording || cameraService.recordingState == .paused
    }

    private func enableLandscape() {
        OrientationManager.shared.allowsLandscape = true
    }

    private func disableLandscape() {
        OrientationManager.shared.allowsLandscape = false
        // Force back to portrait if currently in landscape
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
    }

    init(script: Script, contentOverride: String? = nil) {
        self.script = script
        self.contentOverride = contentOverride
        self._promptSession = State(initialValue: PromptSession(script: script, contentOverride: contentOverride))
    }

    var body: some View {
        ZStack {
            // Camera preview or audio-only background
            if cameraService.recordingMode == .video {
                CameraPreviewView(session: cameraService.captureSession)
                    .ignoresSafeArea()
            } else {
                audioOnlyBackground
            }

            if isLandscape {
                landscapeOverlayLayout

                if isRecording {
                    VStack {
                        topBarContent
                            .padding(.top, SSSpacing.sm)
                        Spacer()
                    }
                }
            } else {
                scriptOverlay
                controlsLayer
            }

            // Framing guide — fades out when recording
            framingGuide
                .opacity(isRecording ? 0 : 1)
                .animation(SSAnimation.standard, value: isRecording)

            // Countdown
            if showCountdown {
                countdownOverlay
            }

            // Take saved banner
            if cameraService.recordingState == .saved {
                takeSavedOverlay
            }

            // Settings panel
            if showSettings {
                settingsPanel
            }

            // Permission denied overlay
            if cameraPermissionDenied || micPermissionDenied {
                permissionDeniedOverlay
            }
        }
        .onAppear {
            enableLandscape()
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            checkPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let newOrientation = UIDevice.current.orientation
            if newOrientation == .portrait || newOrientation == .landscapeLeft || newOrientation == .landscapeRight {
                withAnimation(SSAnimation.standard) {
                    deviceOrientation = newOrientation
                }
                cameraService.updateVideoOrientation(newOrientation)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkPermissions()
        }
        .onDisappear {
            if isRecording {
                cameraService.stopRecording()
            }
            cameraService.stopSession()
            stopAllTimers()
            stopSpeechFollow()
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            disableLandscape()
        }
        .onChange(of: cameraService.recordingMode) { _, newMode in
            guard !isRecording else { return }
            switch newMode {
            case .audioOnly:
                cameraService.teardownSession()
                cameraService.configureAudioOnly()
            case .video:
                cameraService.configure()
                cameraService.startSession()
            }
        }
        .onChange(of: speechEngine.currentWordIndex) { _, newWordIndex in
            guard followMode != .manualScroll else { return }
            // Map word index to sentence index
            let allSentences = sentences
            var cumulative = 0
            var targetSentence = 0
            for (i, sentence) in allSentences.enumerated() {
                let wordCount = sentence.split(separator: " ", omittingEmptySubsequences: true).count
                if newWordIndex < cumulative + wordCount {
                    targetSentence = i
                    break
                }
                cumulative += wordCount
                if i == allSentences.count - 1 {
                    targetSentence = i
                }
            }
            if targetSentence != speechSentenceIndex {
                speechSentenceIndex = targetSentence
                withAnimation(.easeInOut(duration: 0.4)) {
                    smoothScrollY = targetScrollY(for: targetSentence)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .statusBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let url = cameraService.lastSavedURL {
                ShareSheet(items: [url])
            }
        }
        .confirmationDialog("Exit Recording?", isPresented: $showExitConfirmation) {
            Button("Exit", role: .destructive) {
                stopAllTimers()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Script Overlay

    private let overlayHeight: CGFloat = 120

    private var scriptOverlay: some View {
        VStack(spacing: 0) {
            // Eye-line indicator
            Circle()
                .fill(.white.opacity(0.85))
                .frame(width: 8, height: 8)
                .shadow(color: .white.opacity(0.4), radius: 4)
                .padding(.top, 8)
                .opacity(isRecording ? 1 : 0.6)

            // Smooth-scrolling script text
            smoothScrollingScript(fontSize: min(promptSession.textSize, 28), alignment: .center, lineLimit: nil)
                .frame(height: overlayHeight)
                .clipped()
                .background(
                    RoundedRectangle(cornerRadius: SSRadius.lg)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: SSRadius.lg)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.15), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                )
                .padding(.horizontal, SSSpacing.sm)
                .padding(.top, SSSpacing.xxs)

            Spacer()
        }
        .padding(.top, 8)
    }

    private func smoothScrollingScript(fontSize: CGFloat, alignment: TextAlignment, lineLimit: Int?) -> some View {
        let allSentences = sentences
        let lineSpacing = promptSession.lineSpacing * 0.5

        return VStack(spacing: lineSpacing) {
            ForEach(Array(allSentences.enumerated()), id: \.offset) { index, sentence in
                let wordOffset = sentenceWordOffset(for: index)
                highlightedText(
                    content: sentence,
                    globalWordIndex: speechEngine.currentWordIndex,
                    globalWordOffset: wordOffset,
                    currentColor: .white,
                    pastColor: .white.opacity(0.4),
                    futureColor: .white.opacity(0.7),
                    fontSize: fontSize,
                    fontWeight: .medium
                )
                .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                .multilineTextAlignment(alignment)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, SSSpacing.md)
                .frame(maxWidth: .infinity)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: SentenceHeightKey.self,
                            value: [index: geo.size.height]
                        )
                    }
                )
            }
        }
        .padding(.vertical, SSSpacing.sm)
        .offset(y: -smoothScrollY)
        .onPreferenceChange(SentenceHeightKey.self) { heights in
            sentenceHeights.merge(heights) { _, new in new }
        }
    }

    private var scriptContent: String {
        contentOverride ?? script.content
    }

    private var sentences: [String] {
        splitIntoSentences(scriptContent)
    }

    private func sentenceWordOffset(for sentenceIndex: Int) -> Int {
        let allSentences = sentences
        var offset = 0
        for i in 0..<min(sentenceIndex, allSentences.count) {
            offset += allSentences[i].split(separator: " ", omittingEmptySubsequences: true).count
        }
        return offset
    }

    /// Compute the Y offset to scroll to a given sentence index
    private func targetScrollY(for sentenceIndex: Int) -> CGFloat {
        let lineSpacing = promptSession.lineSpacing * 0.5
        var y: CGFloat = 0
        for i in 0..<sentenceIndex {
            y += (sentenceHeights[i] ?? 30) + lineSpacing
        }
        return y
    }

    // MARK: - Top Bar

    private var topBarContent: some View {
        Group {
            if isRecording {
                // Recording state: timer pill + take counter
                HStack {
                    HStack(spacing: SSSpacing.xs) {
                        Circle()
                            .fill(cameraService.recordingState == .paused ? SSColors.slate : SSColors.recordingRed)
                            .frame(width: 10, height: 10)
                            .opacity(cameraService.recordingState == .recording ? (recordingDotVisible ? 1.0 : 0.3) : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recordingDotVisible)

                        Text(formattedDuration)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, SSSpacing.sm)
                    .padding(.vertical, SSSpacing.xxs + 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                    if cameraService.takeCount > 0 {
                        Text("Take \(cameraService.takeCount + 1)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, SSSpacing.xs + 2)
                            .padding(.vertical, SSSpacing.xxs + 2)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Framing Guide

    private var framingGuide: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height
            let guideWidth = isWide ? geometry.size.height * 0.5 : geometry.size.width * 0.7
            let guideHeight = isWide ? guideWidth * 1.4 : guideWidth * 1.2
            RoundedRectangle(cornerRadius: SSRadius.xl)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: guideWidth, height: guideHeight)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.45)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Countdown

    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            // Circular progress ring
            Circle()
                .trim(from: 0, to: countdownProgress)
                .stroke(.white.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))

            Text("\(countdownValue)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .scaleEffect(countdownScale)
                .opacity(countdownOpacity)
        }
    }

    // MARK: - Take Saved

    private var takeSavedOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: SSSpacing.lg) {
                // Green checkmark with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.green.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: takeSavedAppeared)
                }

                Text(cameraService.recordingMode == .audioOnly
                     ? "Audio Take \(cameraService.takeCount) Saved"
                     : "Take \(cameraService.takeCount) Saved")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                VStack(spacing: SSSpacing.sm) {
                    // Primary: Done button
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(SSColors.lavenderMist)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SSSpacing.sm)
                            .background(SSColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
                    }

                    // Secondary row: New Take + Share
                    HStack(spacing: SSSpacing.sm) {
                        Button(action: {
                            takeSavedAppeared = false
                            cameraService.resetForNewTake()
                            promptSession.scrollOffset = 0
                            smoothScrollY = 0
                            speechSentenceIndex = 0
                        }) {
                            Label("New Take", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, SSSpacing.sm)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }

                        if cameraService.lastSavedURL != nil {
                            Button(action: { showShareSheet = true }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, SSSpacing.sm)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(SSSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: SSRadius.xl)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: SSRadius.xl)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, SSSpacing.xl)
            .scaleEffect(takeSavedAppeared ? 1.0 : 0.9)
            .opacity(takeSavedAppeared ? 1.0 : 0)
            .animation(SSAnimation.spring, value: takeSavedAppeared)
            .onAppear { takeSavedAppeared = true }
        }
    }

    // MARK: - Shared Button Components

    private var exitButton: some View {
        Button(action: { isRecording ? showExitConfirmation = true : dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel("Exit")
    }

    private var recordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 78, height: 78)

                Circle()
                    .fill(SSColors.recordingRed)
                    .frame(width: 64, height: 64)
            }
        }
        .accessibilityLabel("Start Recording")
    }

    private var stopRecordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 78, height: 78)

                RoundedRectangle(cornerRadius: 6)
                    .fill(SSColors.recordingRed)
                    .frame(width: 30, height: 30)
            }
        }
        .accessibilityLabel("Stop Recording")
    }

    private var pauseResumeButton: some View {
        Button(action: togglePauseResume) {
            Image(systemName: cameraService.recordingState == .paused ? "play.fill" : "pause.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel(cameraService.recordingState == .paused ? "Resume" : "Pause")
    }

    private var cameraFlipButton: some View {
        Button(action: {
            cameraService.switchCamera()
            SSHaptics.light()
        }) {
            Image(systemName: "camera.rotate")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel("Switch Camera")
    }

    private var settingsButton: some View {
        Button(action: {
            withAnimation(SSAnimation.standard) {
                showSettings.toggle()
            }
        }) {
            Image(systemName: "gear")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .accessibilityLabel("Settings")
    }

    // MARK: - Landscape Layout

    private var landscapeOverlayLayout: some View {
        HStack(spacing: 0) {
            if layoutMode == .landscapeLeft {
                landscapeScriptStrip
                Spacer()
                landscapeControlsStrip
            } else {
                landscapeControlsStrip
                Spacer()
                landscapeScriptStrip
            }
        }
    }

    private var landscapeScriptStrip: some View {
        VStack(spacing: SSSpacing.xs) {
            // Eye-line dot
            Circle()
                .fill(.white.opacity(0.85))
                .frame(width: 8, height: 8)
                .shadow(color: .white.opacity(0.4), radius: 4)
                .padding(.top, SSSpacing.sm)
                .opacity(isRecording ? 1 : 0.6)

            smoothScrollingScript(fontSize: min(promptSession.textSize, 24), alignment: .leading, lineLimit: nil)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipped()
        }
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: SSRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: SSRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.15), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .padding(.vertical, SSSpacing.sm)
        .padding(.horizontal, SSSpacing.xs)
    }

    private var landscapeControlsStrip: some View {
        VStack(spacing: SSSpacing.lg) {
            if isRecording {
                // Top: exit
                exitButton

                Spacer()

                // Center: recording controls
                VStack(spacing: SSSpacing.md) {
                    pauseResumeButton
                    stopRecordButton
                }

                Spacer()

                // Bottom: camera flip during recording
                if cameraService.recordingMode == .video {
                    cameraFlipButton
                        .disabled(cameraService.isSwitchingCamera)
                }
            } else {
                // Top: exit
                exitButton

                Spacer()

                // Center: record button
                recordButton

                Spacer()

                // Bottom: utility buttons grouped together
                VStack(spacing: SSSpacing.sm) {
                    if cameraService.recordingMode == .video {
                        cameraFlipButton
                    }
                    settingsButton
                }
            }
        }
        .frame(width: 90)
        .padding(.vertical, SSSpacing.lg)
        .padding(.horizontal, SSSpacing.xs)
        .animation(SSAnimation.spring, value: isRecording)
    }

    // MARK: - Controls Layer

    private var controlsLayer: some View {
        GeometryReader { geometry in
            ZStack {
                // Exit button + camera flip during recording — top corners
                if isRecording {
                    VStack {
                        HStack {
                            Button(action: { showExitConfirmation = true }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(width: 36, height: 36)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .padding(.leading, SSSpacing.md)
                            .padding(.top, SSSpacing.xxl)

                            Spacer()

                            if cameraService.recordingMode == .video {
                                Button(action: {
                                    cameraService.switchCamera()
                                    SSHaptics.light()
                                }) {
                                    Image(systemName: "camera.rotate")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .frame(width: 36, height: 36)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                .disabled(cameraService.isSwitchingCamera)
                                .padding(.trailing, SSSpacing.md)
                                .padding(.top, SSSpacing.xxl)
                            }
                        }
                        Spacer()
                    }
                }

                // Bottom controls
                VStack {
                    Spacer()

                    if isRecording {
                        // Recording layout: timer + pause + record, centered
                        VStack(spacing: SSSpacing.sm) {
                            // Timer + take counter
                            topBarContent

                            Button(action: togglePauseResume) {
                                Image(systemName: cameraService.recordingState == .paused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 48, height: 48)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel(cameraService.recordingState == .paused ? "Resume" : "Pause")

                            Button(action: toggleRecording) {
                                ZStack {
                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                        .frame(width: 78, height: 78)

                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(SSColors.recordingRed)
                                        .frame(width: 30, height: 30)
                                }
                            }
                            .accessibilityLabel("Stop Recording")
                        }
                        .padding(.bottom, SSSpacing.xxl)
                    } else {
                        // Idle layout: exit — record — flip, with gear top-right
                        HStack(alignment: .center) {
                            // Left: Exit
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 48, height: 48)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Exit")
                            .frame(maxWidth: .infinity)

                            // Center: Record
                            Button(action: toggleRecording) {
                                ZStack {
                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                        .frame(width: 78, height: 78)

                                    Circle()
                                        .fill(SSColors.recordingRed)
                                        .frame(width: 64, height: 64)
                                }
                            }
                            .accessibilityLabel("Start Recording")

                            // Right: Camera flip + gear stacked
                            VStack(spacing: SSSpacing.sm) {
                                if cameraService.recordingMode == .video {
                                    Button(action: {
                                        cameraService.switchCamera()
                                        SSHaptics.light()
                                    }) {
                                        Image(systemName: "camera.rotate")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .frame(width: 48, height: 48)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                    }
                                    .accessibilityLabel("Switch Camera")
                                }

                                Button(action: {
                                    withAnimation(SSAnimation.standard) {
                                        showSettings.toggle()
                                    }
                                }) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                .accessibilityLabel("Settings")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, SSSpacing.lg)
                        .padding(.bottom, SSSpacing.xxl)
                    }
                }
                .animation(SSAnimation.spring, value: isRecording)
            }
        }
    }

    // MARK: - Settings Panel

    private var settingsPanelContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    withAnimation(SSAnimation.standard) {
                        showSettings = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, SSSpacing.lg)
            .padding(.top, SSSpacing.md)

            Divider()
                .background(.white.opacity(0.1))
                .padding(.top, SSSpacing.sm)

            ScrollView {
                VStack(spacing: SSSpacing.lg) {
                    // Recording mode
                    VStack(alignment: .leading, spacing: SSSpacing.xs) {
                        Text("RECORDING MODE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(0.5)

                        Picker("Recording Mode", selection: $cameraService.recordingMode) {
                            ForEach(RecordingMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(isRecording)

                        Text(cameraService.recordingMode == .video
                             ? "Records video with audio from the camera."
                             : "Records audio only. No camera needed.")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 2)
                    }

                    Divider().background(.white.opacity(0.1))

                    // Follow mode
                    VStack(alignment: .leading, spacing: SSSpacing.xs) {
                        Text("FOLLOW MODE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(0.5)

                        Picker("Follow Mode", selection: $followMode) {
                            ForEach(RecordFollowMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(followModeDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 2)
                    }

                    // Scroll speed (only for manual scroll)
                    if followMode == .manualScroll {
                        settingsSliderRow(
                            label: "Scroll Speed",
                            value: $promptSession.scrollSpeed,
                            range: 10...120,
                            unit: "pt/s"
                        )
                    }

                    // Text size
                    settingsSliderRow(
                        label: "Text Size",
                        value: Binding(
                            get: { Double(promptSession.textSize) },
                            set: { promptSession.textSize = CGFloat($0) }
                        ),
                        range: 18...72,
                        unit: "pt"
                    )

                    // Line spacing
                    settingsSliderRow(
                        label: "Line Spacing",
                        value: Binding(
                            get: { Double(promptSession.lineSpacing) },
                            set: { promptSession.lineSpacing = CGFloat($0) }
                        ),
                        range: 4...40,
                        unit: "pt"
                    )

                    if cameraService.recordingMode == .video {
                        Divider().background(.white.opacity(0.1))

                        // Resolution
                        VStack(alignment: .leading, spacing: SSSpacing.xs) {
                            Text("RESOLUTION")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.4))
                                .tracking(0.5)

                            Picker("Resolution", selection: Binding(
                                get: { cameraService.resolution },
                                set: { cameraService.setResolution($0) }
                            )) {
                                ForEach(VideoResolution.allCases, id: \.self) { res in
                                    Text(res.rawValue).tag(res)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Camera
                        VStack(alignment: .leading, spacing: SSSpacing.xs) {
                            Text("CAMERA")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.4))
                                .tracking(0.5)

                            Picker("Camera", selection: Binding(
                                get: { cameraService.currentPosition == .front },
                                set: { _ in cameraService.switchCamera() }
                            )) {
                                Text("Front").tag(true)
                                Text("Back").tag(false)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .padding(SSSpacing.lg)
            }
            .frame(maxHeight: isLandscape ? .infinity : 380)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: SSRadius.xl))
    }

    private var settingsPanel: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(SSAnimation.standard) {
                        showSettings = false
                    }
                }

            if isLandscape {
                // Landscape: slide from controls side
                HStack {
                    if layoutMode == .landscapeLeft {
                        Spacer()
                        settingsPanelContent
                            .frame(maxWidth: 320)
                            .padding(.trailing, SSSpacing.sm)
                            .padding(.vertical, SSSpacing.sm)
                    } else {
                        settingsPanelContent
                            .frame(maxWidth: 320)
                            .padding(.leading, SSSpacing.sm)
                            .padding(.vertical, SSSpacing.sm)
                        Spacer()
                    }
                }
                .transition(.move(edge: layoutMode == .landscapeLeft ? .trailing : .leading))
            } else {
                // Portrait: slide from bottom
                VStack {
                    Spacer()

                    VStack(spacing: 0) {
                        Capsule()
                            .fill(.white.opacity(0.3))
                            .frame(width: 36, height: 4)
                            .padding(.top, SSSpacing.sm)

                        settingsPanelContent
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: SSRadius.xl))
                    .padding(.horizontal, SSSpacing.sm)
                    .padding(.bottom, SSSpacing.xs)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .transition(.opacity)
    }

    private var followModeDescription: String {
        switch followMode {
        case .speechSmart: "Listens to your voice and follows along. Tolerates pauses and filler words."
        case .speechStrict: "Advances word-by-word as you speak. Best for precise reading."
        case .manualScroll: "Auto-scrolls at a fixed speed. Adjust speed below."
        }
    }

    private func settingsSliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: SSSpacing.xs) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(0.5)
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Slider(value: value, in: range, step: 1)
                .tint(SSColors.accent)
        }
    }

    // MARK: - Actions

    private func toggleRecording() {
        switch cameraService.recordingState {
        case .recording, .paused:
            cameraService.stopRecording()
            promptSession.pause()
            stopScrollTimer()
            stopDurationTimer()
            stopSpeechFollow()
            SSHaptics.medium()
        case .idle:
            startCountdown()
        case .saved:
            cameraService.resetForNewTake()
            promptSession.scrollOffset = 0
            startCountdown()
        default:
            break
        }
    }

    private func togglePauseResume() {
        if cameraService.recordingState == .recording {
            cameraService.pauseRecording()
            promptSession.pause()
            SSHaptics.light()
        } else if cameraService.recordingState == .paused {
            cameraService.resumeRecording()
            promptSession.play()
            SSHaptics.light()
        }
    }

    private func startCountdown() {
        countdownValue = 3
        showCountdown = true
        recordingDuration = 0
        countdownProgress = 1.0
        countdownScale = 1.5
        countdownOpacity = 1.0
        SSHaptics.medium()

        animateCountdownTick()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdownValue > 1 {
                countdownValue -= 1
                SSHaptics.light()
                animateCountdownTick()
            } else {
                countdownTimer?.invalidate()
                countdownTimer = nil
                showCountdown = false
                cameraService.startRecording()
                recordingDotVisible.toggle()
                promptSession.play()
                if followMode == .manualScroll {
                    startScrollTimer()
                } else {
                    startSpeechFollow()
                }
                startDurationTimer()
            }
        }
    }

    private func animateCountdownTick() {
        countdownScale = 1.5
        countdownOpacity = 1.0
        let targetProgress = CGFloat(countdownValue - 1) / 3.0

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            countdownScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.8)) {
            countdownOpacity = 0.3
        }
        withAnimation(.linear(duration: 0.95)) {
            countdownProgress = targetProgress
        }
    }

    private func startSpeechFollow() {
        speechEngine.mode = followMode == .speechStrict ? .strict : .smart
        speechEngine.prepare(scriptContent: scriptContent)
        // Configure audio session for both camera/audio and speech to share
        let audioSession = AVAudioSession.sharedInstance()
        let mode: AVAudioSession.Mode = cameraService.recordingMode == .video ? .videoRecording : .spokenAudio
        try? audioSession.setCategory(.playAndRecord, mode: mode, options: [.defaultToSpeaker, .allowBluetooth])
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        // Use existing audio session since CameraService manages it
        speechEngine.start(useExistingAudioSession: true)
        speechSentenceIndex = 0
        smoothScrollY = 0
    }

    private func stopSpeechFollow() {
        speechEngine.stop()
    }

    private func startScrollTimer() {
        stopScrollTimer()
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard promptSession.state == .prompting else { return }
            smoothScrollY += promptSession.scrollSpeed / 60.0
        }
    }

    private func startDurationTimer() {
        recordingStartTime = Date()
        recordingDuration = 0
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if let start = recordingStartTime {
                recordingDuration = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    private func stopScrollTimer() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }

    private func stopAllTimers() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        stopScrollTimer()
        stopDurationTimer()
    }

    private var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func checkPermissions() {
        if cameraService.recordingMode == .audioOnly {
            checkAudioOnlyPermissions()
            return
        }

        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        if cameraStatus == .denied || cameraStatus == .restricted {
            cameraPermissionDenied = true
        } else if cameraStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        checkMicAndStart()
                    } else {
                        cameraPermissionDenied = true
                    }
                }
            }
            return
        }

        if micStatus == .denied || micStatus == .restricted {
            micPermissionDenied = true
        } else if micStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if !granted { micPermissionDenied = true }
                    cameraService.configure()
                    cameraService.startSession()
                }
            }
            return
        }

        if !cameraPermissionDenied {
            cameraService.configure()
            cameraService.startSession()
        }
    }

    private func checkAudioOnlyPermissions() {
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .denied || micStatus == .restricted {
            micPermissionDenied = true
        } else if micStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        cameraService.configureAudioOnly()
                    } else {
                        micPermissionDenied = true
                    }
                }
            }
        } else {
            cameraService.configureAudioOnly()
        }
    }

    private func checkMicAndStart() {
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if !granted { micPermissionDenied = true }
                    cameraService.configure()
                    cameraService.startSession()
                }
            }
        } else {
            if micStatus == .denied || micStatus == .restricted {
                micPermissionDenied = true
            }
            cameraService.configure()
            cameraService.startSession()
        }
    }

    private var permissionDeniedTitle: String {
        if cameraPermissionDenied && micPermissionDenied {
            return "Camera & Microphone Access Required"
        } else if cameraPermissionDenied {
            return "Camera Access Required"
        } else {
            return "Microphone Access Required"
        }
    }

    private var permissionDeniedMessage: String {
        if cameraPermissionDenied && micPermissionDenied {
            return "ScriptSeer needs camera and microphone access to record video. Please enable both in Settings."
        } else if cameraPermissionDenied {
            return "ScriptSeer needs camera access to record video. Please enable it in Settings."
        } else {
            return "ScriptSeer needs microphone access for audio recording. Please enable it in Settings."
        }
    }

    // MARK: - Audio-Only Background

    private var audioOnlyBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.08), Color(white: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: SSSpacing.lg) {
                Image(systemName: "waveform")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.white.opacity(isRecording ? 0.6 : 0.3))

                AudioWaveformView(level: cameraService.audioLevel, isRecording: isRecording)

                Text(isRecording ? "Recording Audio" : "Audio Only Mode")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var permissionDeniedOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: SSSpacing.lg) {
                Image(systemName: cameraPermissionDenied ? "camera.fill" : "mic.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.6))

                Text(permissionDeniedTitle)
                    .font(SSTypography.headline)
                    .foregroundStyle(.white)

                Text(permissionDeniedMessage)
                    .font(SSTypography.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SSSpacing.xl)

                HStack(spacing: SSSpacing.md) {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(SSTypography.headline)
                    .foregroundStyle(SSColors.lavenderMist)
                    .padding(.horizontal, SSSpacing.lg)
                    .padding(.vertical, SSSpacing.sm)
                    .background(SSColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))

                    Button("Go Back") { dismiss() }
                        .font(SSTypography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, SSSpacing.lg)
                        .padding(.vertical, SSSpacing.sm)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
                }
            }
        }
    }
}

private struct SentenceHeightKey: PreferenceKey {
    static let defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}
