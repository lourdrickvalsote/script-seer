import SwiftUI
import AVFoundation

struct CameraRecordView: View {
    @Environment(\.dismiss) private var dismiss
    let script: Script
    @State private var cameraService = CameraService()
    @State private var promptSession: PromptSession
    @State private var countdownValue = 3
    @State private var showCountdown = false
    @State private var timer: Timer?
    @State private var recordingStartTime: Date?
    @State private var recordingDuration: TimeInterval = 0
    @State private var durationTimer: Timer?
    @State private var showExitConfirmation = false
    @State private var showShareSheet = false
    @State private var showSettings = false
    @State private var cameraPermissionDenied = false
    @State private var micPermissionDenied = false
    @State private var recordingDotVisible = true

    init(script: Script) {
        self.script = script
        self._promptSession = State(initialValue: PromptSession(script: script))
    }

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(session: cameraService.captureSession)
                .ignoresSafeArea()

            // Script overlay near top (near lens area for eye contact)
            scriptOverlay

            // Framing guide
            framingGuide

            // Countdown
            if showCountdown {
                countdownOverlay
            }

            // Take saved banner
            if cameraService.recordingState == .saved {
                takeSavedOverlay
            }

            // Controls
            VStack(spacing: 0) {
                // Top bar: timer + take counter (below script overlay)
                if cameraService.recordingState == .recording || cameraService.recordingState == .paused {
                    topRecordingBar
                        .padding(.top, 70)
                }

                Spacer()
                controlBar
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
            checkPermissions()
        }
        .onDisappear {
            if cameraService.recordingState == .recording || cameraService.recordingState == .paused {
                cameraService.stopRecording()
            }
            cameraService.stopSession()
            stopTimer()
            stopDurationTimer()
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
                stopTimer()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Top Recording Bar

    private var topRecordingBar: some View {
        HStack {
            // Recording indicator
            HStack(spacing: SSSpacing.xs) {
                Circle()
                    .fill(cameraService.recordingState == .paused ? SSColors.slate : SSColors.recordingRed)
                    .frame(width: 10, height: 10)
                    .opacity(cameraService.recordingState == .recording ? (recordingDotVisible ? 1.0 : 0.3) : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recordingDotVisible)
                    .onAppear { recordingDotVisible.toggle() }

                Text(formattedDuration)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, SSSpacing.sm)
            .padding(.vertical, SSSpacing.xxs)
            .background(.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))

            Spacer()

            // Take counter
            if cameraService.takeCount > 0 {
                Text("Take \(cameraService.takeCount + 1)")
                    .font(SSTypography.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, SSSpacing.sm)
                    .padding(.vertical, SSSpacing.xxs)
                    .background(.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))
            }
        }
        .padding(.horizontal, SSSpacing.md)
    }

    // MARK: - Script Overlay

    private var scriptOverlay: some View {
        VStack {
            // Compact text box right below the Dynamic Island
            Text(currentText)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, x: 0, y: 1)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, SSSpacing.md)
                .padding(.vertical, SSSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: SSRadius.sm)
                        .fill(.black.opacity(0.55))
                )
                .padding(.horizontal, SSSpacing.sm)

            Spacer()
        }
    }

    private var currentText: String {
        // Show only 2 lines at a time for a compact overlay
        let lines = script.content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let totalOffset = promptSession.scrollOffset
        let lineIndex = min(Int(totalOffset / 60), max(lines.count - 1, 0))
        let endIndex = min(lineIndex + 3, lines.count)
        guard lineIndex < lines.count else { return "" }
        return lines[lineIndex..<endIndex].joined(separator: "\n")
    }

    // MARK: - Framing Guide

    private var framingGuide: some View {
        GeometryReader { geometry in
            let guideWidth = geometry.size.width * 0.7
            let guideHeight = guideWidth * 1.2
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
            Text("\(countdownValue)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Take Saved

    private var takeSavedOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: SSSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Take \(cameraService.takeCount) Saved")
                    .font(SSTypography.headline)
                    .foregroundStyle(.white)

                HStack(spacing: SSSpacing.sm) {
                    Button(action: {
                        cameraService.resetForNewTake()
                        promptSession.scrollOffset = 0
                    }) {
                        Label("New Take", systemImage: "arrow.counterclockwise")
                            .font(SSTypography.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, SSSpacing.sm)
                            .padding(.vertical, SSSpacing.sm)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
                    }

                    if cameraService.lastSavedURL != nil {
                        Button(action: { showShareSheet = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(SSTypography.subheadline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, SSSpacing.sm)
                                .padding(.vertical, SSSpacing.sm)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
                        }
                    }

                    Button(action: { dismiss() }) {
                        Label("Done", systemImage: "checkmark")
                            .font(SSTypography.subheadline)
                            .foregroundStyle(SSColors.lavenderMist)
                            .padding(.horizontal, SSSpacing.sm)
                            .padding(.vertical, SSSpacing.sm)
                            .background(SSColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: SSRadius.md))
                    }
                }
            }
            .padding(SSSpacing.lg)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.xl))
            .padding(.horizontal, SSSpacing.lg)

            Spacer()
        }
    }

    // MARK: - Controls

    private var controlBar: some View {
        HStack(spacing: SSSpacing.xl) {
            // Exit
            Button(action: {
                if cameraService.recordingState == .recording || cameraService.recordingState == .paused {
                    showExitConfirmation = true
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Exit")

            // Pause / Resume (only while recording)
            if cameraService.recordingState == .recording || cameraService.recordingState == .paused {
                Button(action: togglePauseResume) {
                    Image(systemName: cameraService.recordingState == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel(cameraService.recordingState == .paused ? "Resume" : "Pause")
            }

            // Record / Stop button
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 72, height: 72)

                    if cameraService.recordingState == .recording || cameraService.recordingState == .paused {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(SSColors.recordingRed)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle()
                            .fill(SSColors.recordingRed)
                            .frame(width: 60, height: 60)
                    }
                }
            }
            .accessibilityLabel(cameraService.recordingState == .recording || cameraService.recordingState == .paused ? "Stop Recording" : "Start Recording")

            // Switch camera (not during recording)
            if cameraService.recordingState != .recording && cameraService.recordingState != .paused {
                Button(action: {
                    cameraService.switchCamera()
                    SSHaptics.light()
                }) {
                    Image(systemName: "camera.rotate")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Switch Camera")
            }

            // Settings (not during recording)
            if cameraService.recordingState == .idle {
                Button(action: {
                    withAnimation(SSAnimation.standard) {
                        showSettings.toggle()
                    }
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Settings")
            }
        }
        .padding(.bottom, SSSpacing.xl)
    }

    // MARK: - Settings Panel

    private var settingsPanel: some View {
        VStack {
            Spacer()

            VStack(spacing: SSSpacing.md) {
                Text("Recording Settings")
                    .font(SSTypography.headline)
                    .foregroundStyle(.white)

                // Resolution picker
                VStack(alignment: .leading, spacing: SSSpacing.xs) {
                    Text("Resolution")
                        .font(SSTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))

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

                // Camera position
                VStack(alignment: .leading, spacing: SSSpacing.xs) {
                    Text("Camera")
                        .font(SSTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    Picker("Camera", selection: Binding(
                        get: { cameraService.currentPosition == .front },
                        set: { _ in cameraService.switchCamera() }
                    )) {
                        Text("Front").tag(true)
                        Text("Back").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                Button("Done") {
                    withAnimation(SSAnimation.standard) {
                        showSettings = false
                    }
                }
                .foregroundStyle(SSColors.accent)
            }
            .padding(SSSpacing.lg)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: SSRadius.xl))
            .padding(.horizontal, SSSpacing.md)
            .padding(.bottom, 120)
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
            SSHaptics.medium()
        case .idle:
            startCountdown()
        case .saved:
            // Start new take
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
        SSHaptics.medium()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdownValue > 1 {
                countdownValue -= 1
                SSHaptics.light()
            } else {
                stopTimer()
                showCountdown = false
                cameraService.startRecording()
                promptSession.play()
                startScrollTimer()
                startDurationTimer()
            }
        }
    }

    private func startScrollTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard promptSession.state == .prompting else { return }
            promptSession.scrollOffset += promptSession.scrollSpeed / 60.0
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
        stopTimer()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func checkPermissions() {
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

    private var permissionDeniedOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: SSSpacing.lg) {
                Image(systemName: cameraPermissionDenied ? "camera.fill" : "mic.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.6))

                Text(cameraPermissionDenied ? "Camera Access Required" : "Microphone Access Required")
                    .font(SSTypography.headline)
                    .foregroundStyle(.white)

                Text(cameraPermissionDenied
                     ? "ScriptSeer needs camera access to record video. Please enable it in Settings."
                     : "ScriptSeer needs microphone access for audio recording. Please enable it in Settings.")
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
