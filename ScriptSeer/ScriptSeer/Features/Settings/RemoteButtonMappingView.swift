import SwiftUI

struct RemoteButtonMappingView: View {
    @State private var remoteInput = RemoteInputService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: SSSpacing.lg) {
                // Game Controller Mapping
                SettingsMappingSection("Game Controller Buttons") {
                    VStack(spacing: 0) {
                        ForEach(Array(GamepadButton.allCases.enumerated()), id: \.element) { index, button in
                            if index > 0 {
                                Rectangle()
                                    .fill(SSColors.divider)
                                    .frame(height: 0.5)
                                    .padding(.vertical, SSSpacing.xs)
                            }

                            HStack {
                                Text(button.displayName)
                                    .font(SSTypography.body)
                                    .foregroundStyle(SSColors.textPrimary)

                                Spacer()

                                Picker("", selection: mappingBinding(for: button)) {
                                    ForEach(RemoteAction.allCases, id: \.self) { action in
                                        Text(action.displayName).tag(action)
                                    }
                                }
                                .labelsHidden()
                                .tint(SSColors.accent)
                            }
                        }
                    }
                }

                // Keyboard Shortcuts (informational)
                SettingsMappingSection("Keyboard Shortcuts") {
                    VStack(spacing: 0) {
                        shortcutRow("Space", "Play / Pause")
                        mappingDivider
                        shortcutRow("Up / Down Arrow", "Speed Up / Down")
                        mappingDivider
                        shortcutRow("Left / Right Arrow", "Jump Back / Forward")
                        mappingDivider
                        shortcutRow("Page Up / Down", "Jump Back / Forward")
                        mappingDivider
                        shortcutRow("Return", "Play / Pause")
                        mappingDivider
                        shortcutRow("S", "Mark Stumble (Practice)")
                        mappingDivider
                        shortcutRow("Escape", "Exit")
                    }
                }

                // Reset
                Button {
                    remoteInput.gameController.resetMapping()
                    SSHaptics.light()
                } label: {
                    Text("Reset to Defaults")
                        .font(SSTypography.body)
                        .foregroundStyle(SSColors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SSSpacing.sm)
                }

                Spacer().frame(height: SSSpacing.md)
            }
            .padding(.horizontal, SSSpacing.md)
            .padding(.top, SSSpacing.xs)
        }
        .background(SSColors.background)
        .navigationTitle("Button Mapping")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func mappingBinding(for button: GamepadButton) -> Binding<RemoteAction> {
        Binding(
            get: { remoteInput.gameController.buttonMapping[button] ?? .playPause },
            set: { newAction in
                remoteInput.gameController.buttonMapping[button] = newAction
                remoteInput.gameController.saveMapping()
            }
        )
    }

    private func shortcutRow(_ key: String, _ action: String) -> some View {
        HStack {
            Text(key)
                .font(SSTypography.body)
                .foregroundStyle(SSColors.textPrimary)
            Spacer()
            Text(action)
                .font(SSTypography.caption)
                .foregroundStyle(SSColors.textTertiary)
        }
    }

    private var mappingDivider: some View {
        Rectangle()
            .fill(SSColors.divider)
            .frame(height: 0.5)
            .padding(.vertical, SSSpacing.xs)
    }
}

// MARK: - Section Card (matches SettingsView style)

private struct SettingsMappingSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SSSpacing.xs) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SSColors.textTertiary)
                .padding(.leading, SSSpacing.xs)

            SSCard {
                content
            }
        }
    }
}
