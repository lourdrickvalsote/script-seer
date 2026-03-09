import SwiftUI

struct AudioSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var service: AudioRecordingService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SSSpacing.lg) {
                    // Format picker
                    SSGlassPanel {
                        VStack(alignment: .leading, spacing: SSSpacing.sm) {
                            Text("Format")
                                .font(SSTypography.footnote)
                                .foregroundStyle(SSColors.textTertiary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Picker("Format", selection: $service.selectedFormat) {
                                ForEach(AudioFormat.allCases) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    // Sample rate picker
                    SSGlassPanel {
                        VStack(alignment: .leading, spacing: SSSpacing.sm) {
                            Text("Sample Rate")
                                .font(SSTypography.footnote)
                                .foregroundStyle(SSColors.textTertiary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Picker("Sample Rate", selection: $service.selectedSampleRate) {
                                ForEach(AudioSampleRate.allCases) { rate in
                                    Text(rate.displayName).tag(rate)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    // Estimated file size
                    SSGlassPanel {
                        VStack(alignment: .leading, spacing: SSSpacing.sm) {
                            Text("Estimated File Size")
                                .font(SSTypography.footnote)
                                .foregroundStyle(SSColors.textTertiary)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            HStack {
                                Label {
                                    Text(estimatedSizeText)
                                        .font(SSTypography.body)
                                        .foregroundStyle(SSColors.textPrimary)
                                } icon: {
                                    Image(systemName: "internaldrive")
                                        .foregroundStyle(SSColors.accent)
                                }

                                Spacer()
                            }

                            if isHighStorage {
                                HStack(spacing: SSSpacing.xxs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.orange)
                                    Text("Large file sizes at this quality")
                                        .font(SSTypography.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, SSSpacing.md)
                .padding(.top, SSSpacing.md)
            }
            .background(SSColors.background)
            .navigationTitle("Audio Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(SSColors.accent)
                }
            }
        }
    }

    private var estimatedSizeText: String {
        let bytesPerSecond = service.selectedSampleRate.estimatedBytesPerSecond(format: service.selectedFormat)
        let perMinute = Int64(bytesPerSecond * 60)
        let fiveMinutes = perMinute * 5
        let perMinuteStr = ByteCountFormatter.string(fromByteCount: perMinute, countStyle: .file)
        let fiveMinStr = ByteCountFormatter.string(fromByteCount: fiveMinutes, countStyle: .file)
        return "\(perMinuteStr)/min · ~\(fiveMinStr) for 5 min"
    }

    private var isHighStorage: Bool {
        let bytesPerSecond = service.selectedSampleRate.estimatedBytesPerSecond(format: service.selectedFormat)
        // Warn if 5 minutes would exceed 50MB
        return bytesPerSecond * 300 > 50_000_000
    }
}
