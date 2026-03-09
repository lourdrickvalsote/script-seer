import SwiftUI

struct AudioTakeRow: View {
    let take: AudioTake
    @State private var playbackService = AudioPlaybackService()
    @State private var expanded = false
    @State private var showShareSheet = false

    var body: some View {
        SSCard {
            VStack(spacing: 0) {
                // Header row
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if expanded {
                            playbackService.stop()
                            expanded = false
                        } else {
                            expanded = true
                        }
                    }
                } label: {
                    HStack(spacing: SSSpacing.sm) {
                        VStack(alignment: .leading, spacing: SSSpacing.xxxs) {
                            Text(take.title.isEmpty ? "Take" : take.title)
                                .font(SSTypography.headline)
                                .foregroundStyle(SSColors.textPrimary)
                                .lineLimit(1)

                            HStack(spacing: SSSpacing.xs) {
                                Text(take.formattedDuration)
                                Text("·")
                                    .foregroundStyle(SSColors.textTertiary)
                                Text(take.date.formatted(.relative(presentation: .named)))
                                Text("·")
                                    .foregroundStyle(SSColors.textTertiary)
                                Text(take.formattedFileSize)
                            }
                            .font(SSTypography.caption)
                            .foregroundStyle(SSColors.textSecondary)
                        }

                        Spacer()

                        Text(take.formatDisplayName)
                            .font(SSTypography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(SSColors.accent)
                            .padding(.horizontal, SSSpacing.xs)
                            .padding(.vertical, SSSpacing.xxxs)
                            .background(
                                Capsule()
                                    .fill(SSColors.accentSubtle)
                            )

                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(SSColors.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                // Expanded playback controls
                if expanded {
                    Divider()
                        .background(SSColors.divider)
                        .padding(.vertical, SSSpacing.sm)

                    if let fileURL = take.fileURL {
                        VStack(spacing: SSSpacing.sm) {
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(SSColors.surfaceElevated)
                                        .frame(height: 4)

                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(SSColors.accent)
                                        .frame(width: geo.size.width * playbackService.progress, height: 4)
                                }
                            }
                            .frame(height: 4)

                            HStack {
                                Text(formatTime(playbackService.currentTime))
                                    .font(SSTypography.caption.monospacedDigit())
                                    .foregroundStyle(SSColors.textSecondary)

                                Spacer()

                                Button {
                                    if playbackService.isPlaying {
                                        playbackService.pause()
                                    } else if playbackService.currentTime > 0 {
                                        playbackService.resume()
                                    } else {
                                        playbackService.play(url: fileURL)
                                    }
                                } label: {
                                    Image(systemName: playbackService.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(SSColors.accent)
                                        .frame(width: 44, height: 44)
                                }

                                Spacer()

                                Text(formatTime(take.duration))
                                    .font(SSTypography.caption.monospacedDigit())
                                    .foregroundStyle(SSColors.textSecondary)
                            }
                        }
                    } else {
                        Text("File unavailable on this device")
                            .font(SSTypography.footnote)
                            .foregroundStyle(SSColors.textTertiary)
                            .padding(.vertical, SSSpacing.xs)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = take.fileURL {
                ShareSheet(items: [url])
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Handled by parent via onDelete
        }
        .onDisappear {
            playbackService.stop()
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
