import SwiftUI
import SwiftData

struct AudioRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let script: Script
    @State private var recordingService = AudioRecordingService()
    @State private var showSettings = false
    @State private var showExitConfirmation = false
    @State private var showTakes = true

    private var takeCount: Int {
        script.audioTakes.count
    }

    private var isRecording: Bool {
        recordingService.recordingState == .recording || recordingService.recordingState == .paused
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar

            Spacer()

            // Waveform + timer
            centerContent

            Spacer()

            // Recording controls
            controlsSection

            // Inline takes list
            if showTakes && !script.audioTakes.isEmpty {
                takesSection
            }
        }
        .background(SSColors.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showSettings) {
            AudioSettingsSheet(service: recordingService)
                .presentationDetents([.medium])
        }
        .alert("Discard Recording?", isPresented: $showExitConfirmation) {
            Button("Discard", role: .destructive) {
                recordingService.discardRecording()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have an active recording that will be lost.")
        }
        .onAppear {
            recordingService.configureSession()
        }
        .onDisappear {
            if isRecording {
                recordingService.discardRecording()
            }
            recordingService.deactivateSession()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                if isRecording {
                    showExitConfirmation = true
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SSColors.textSecondary)
            }

            Spacer()

            Text(script.title)
                .font(SSTypography.headline)
                .foregroundStyle(SSColors.textPrimary)
                .lineLimit(1)

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "gear")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SSColors.textSecondary)
            }
            .disabled(isRecording)
            .opacity(isRecording ? 0.4 : 1)
        }
        .padding(.horizontal, SSSpacing.md)
        .padding(.top, SSSpacing.sm)
    }

    // MARK: - Center Content

    private var centerContent: some View {
        VStack(spacing: SSSpacing.lg) {
            // Take counter
            if takeCount > 0 || isRecording {
                Text("Take \(takeCount + (isRecording ? 1 : 0))")
                    .font(SSTypography.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(SSColors.accent)
                    .padding(.horizontal, SSSpacing.sm)
                    .padding(.vertical, SSSpacing.xxxs)
                    .background(
                        Capsule()
                            .fill(SSColors.accentSubtle)
                    )
            }

            // Large waveform
            AudioWaveformView(
                level: recordingService.audioLevel,
                isRecording: recordingService.recordingState == .recording,
                size: .large
            )

            // Timer
            Text(formatDuration(recordingService.currentDuration))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(SSColors.textPrimary)

            // Format + sample rate info
            HStack(spacing: SSSpacing.xs) {
                Text(recordingService.selectedFormat.shortName)
                Text("·")
                    .foregroundStyle(SSColors.textTertiary)
                Text(recordingService.selectedSampleRate.displayName)
            }
            .font(SSTypography.caption)
            .foregroundStyle(SSColors.textSecondary)
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        HStack(spacing: SSSpacing.xl) {
            // Discard button (left)
            if isRecording {
                Button {
                    recordingService.discardRecording()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(SSColors.textSecondary)
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(SSColors.surfaceElevated)
                        )
                }
            } else {
                Spacer().frame(width: 52, height: 52)
            }

            // Record / Stop button (center)
            Button {
                handleMainButton()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 72, height: 72)

                    if isRecording {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red)
                            .frame(width: 28, height: 28)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 58, height: 58)
                    }
                }
            }

            // Pause/Resume button (right)
            if recordingService.recordingState == .recording {
                Button {
                    recordingService.pauseRecording()
                    SSHaptics.light()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(SSColors.surfaceElevated)
                        )
                }
            } else if recordingService.recordingState == .paused {
                Button {
                    recordingService.resumeRecording()
                    SSHaptics.light()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(SSColors.accent)
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(SSColors.surfaceElevated)
                        )
                }
            } else {
                Spacer().frame(width: 52, height: 52)
            }
        }
        .padding(.bottom, SSSpacing.lg)
    }

    // MARK: - Takes List

    private var takesSection: some View {
        VStack(alignment: .leading, spacing: SSSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showTakes.toggle()
                }
            } label: {
                HStack {
                    Text("Takes")
                        .font(SSTypography.footnote)
                        .foregroundStyle(SSColors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text("\(script.audioTakes.count)")
                        .font(SSTypography.caption)
                        .foregroundStyle(SSColors.textSecondary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SSColors.textTertiary)
                }
            }
            .padding(.horizontal, SSSpacing.md)

            ScrollView {
                VStack(spacing: SSSpacing.xs) {
                    ForEach(script.audioTakes.sorted { $0.date > $1.date }) { take in
                        AudioTakeRow(take: take)
                            .contextMenu {
                                if take.fileURL != nil {
                                    Button {
                                        // Share handled in row
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                }
                                Button(role: .destructive) {
                                    AudioFileManager.deleteFile(fileName: take.fileName)
                                    modelContext.delete(take)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, SSSpacing.md)
            }
            .frame(maxHeight: 200)
        }
        .padding(.bottom, SSSpacing.md)
    }

    // MARK: - Actions

    private func handleMainButton() {
        switch recordingService.recordingState {
        case .idle, .stopped:
            _ = recordingService.startRecording()
            SSHaptics.medium()
        case .recording, .paused:
            saveTake()
            SSHaptics.success()
        case .failed:
            recordingService.reset()
        }
    }

    private func saveTake() {
        guard let url = recordingService.stopRecording(),
              let result = recordingService.persistTake(url: url) else { return }

        let take = AudioTake(
            title: "Take \(takeCount + 1)",
            duration: recordingService.currentDuration,
            fileName: result.fileName,
            audioFormat: recordingService.selectedFormat.rawValue,
            sampleRate: recordingService.selectedSampleRate.rawValue,
            fileSize: result.fileSize,
            script: script
        )
        modelContext.insert(take)
        recordingService.reset()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
