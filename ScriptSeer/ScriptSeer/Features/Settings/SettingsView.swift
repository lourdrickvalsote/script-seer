import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    SettingsRow(icon: "textformat.size", title: "Prompt Defaults")
                    SettingsRow(icon: "waveform", title: "Speech Follow")
                    SettingsRow(icon: "camera", title: "Camera Defaults")
                } header: {
                    Text("Prompting")
                        .foregroundStyle(SSColors.textTertiary)
                }

                Section {
                    SettingsRow(icon: "paintbrush", title: "Appearance")
                    SettingsRow(icon: "hand.tap", title: "Haptics")
                } header: {
                    Text("General")
                        .foregroundStyle(SSColors.textTertiary)
                }

                Section {
                    SettingsRow(icon: "star", title: "ScriptSeer Pro")
                    SettingsRow(icon: "arrow.clockwise", title: "Restore Purchases")
                } header: {
                    Text("Subscription")
                        .foregroundStyle(SSColors.textTertiary)
                }

                Section {
                    SettingsRow(icon: "questionmark.circle", title: "Help & Support")
                    SettingsRow(icon: "info.circle", title: "About")
                } header: {
                    Text("More")
                        .foregroundStyle(SSColors.textTertiary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(SSColors.background)
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: SSSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SSColors.accent)
                .frame(width: 28, height: 28)
                .background(SSColors.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))

            Text(title)
                .font(SSTypography.body)
                .foregroundStyle(SSColors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SSColors.textTertiary)
        }
        .padding(.vertical, SSSpacing.xxs)
        .listRowBackground(SSColors.surfaceElevated)
    }
}
