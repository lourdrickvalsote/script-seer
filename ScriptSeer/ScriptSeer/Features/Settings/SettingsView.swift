import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultScrollSpeed") private var defaultScrollSpeed = 40.0
    @AppStorage("defaultTextSize") private var defaultTextSize = 32.0
    @AppStorage("defaultLineSpacing") private var defaultLineSpacing = 16.0
    @AppStorage("defaultCountdown") private var defaultCountdown = 3
    @AppStorage("speechFollowMode") private var speechFollowMode = "Smart"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        NavigationStack {
            List {
                // Prompt defaults
                Section {
                    HStack {
                        Text("Scroll Speed")
                            .foregroundStyle(SSColors.textPrimary)
                        Spacer()
                        Text("\(Int(defaultScrollSpeed)) pt/s")
                            .foregroundStyle(SSColors.textTertiary)
                    }
                    Slider(value: $defaultScrollSpeed, in: 10...120)
                        .tint(SSColors.accent)

                    HStack {
                        Text("Text Size")
                            .foregroundStyle(SSColors.textPrimary)
                        Spacer()
                        Text("\(Int(defaultTextSize)) pt")
                            .foregroundStyle(SSColors.textTertiary)
                    }
                    Slider(value: $defaultTextSize, in: 18...72)
                        .tint(SSColors.accent)

                    HStack {
                        Text("Line Spacing")
                            .foregroundStyle(SSColors.textPrimary)
                        Spacer()
                        Text("\(Int(defaultLineSpacing)) pt")
                            .foregroundStyle(SSColors.textTertiary)
                    }
                    Slider(value: $defaultLineSpacing, in: 4...40)
                        .tint(SSColors.accent)

                    Picker("Countdown", selection: $defaultCountdown) {
                        ForEach([0, 3, 5, 10], id: \.self) { val in
                            Text(val == 0 ? "None" : "\(val)s").tag(val)
                        }
                    }
                    .foregroundStyle(SSColors.textPrimary)
                } header: {
                    Text("Prompt Defaults")
                        .foregroundStyle(SSColors.textTertiary)
                }
                .listRowBackground(SSColors.surfaceElevated)

                // Speech follow
                Section {
                    Picker("Default Mode", selection: $speechFollowMode) {
                        Text("Strict").tag("Strict")
                        Text("Smart").tag("Smart")
                    }
                    .foregroundStyle(SSColors.textPrimary)
                } header: {
                    Text("Speech Follow")
                        .foregroundStyle(SSColors.textTertiary)
                }
                .listRowBackground(SSColors.surfaceElevated)

                // General
                Section {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .foregroundStyle(SSColors.textPrimary)
                        .tint(SSColors.accent)

                    Button(action: { hasSeenOnboarding = false }) {
                        HStack {
                            Text("Show Onboarding Tips")
                                .foregroundStyle(SSColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundStyle(SSColors.accent)
                        }
                    }
                } header: {
                    Text("General")
                        .foregroundStyle(SSColors.textTertiary)
                }
                .listRowBackground(SSColors.surfaceElevated)

                // Pro
                Section {
                    NavigationLink(destination: ProUpgradeView()) {
                        SettingsRow(icon: "star", title: "ScriptSeer Pro")
                    }
                    Button(action: {}) {
                        SettingsRow(icon: "arrow.clockwise", title: "Restore Purchases")
                    }
                } header: {
                    Text("Subscription")
                        .foregroundStyle(SSColors.textTertiary)
                }
                .listRowBackground(SSColors.surfaceElevated)

                // About
                Section {
                    SettingsRow(icon: "info.circle", title: "About ScriptSeer")
                } header: {
                    Text("More")
                        .foregroundStyle(SSColors.textTertiary)
                }
                .listRowBackground(SSColors.surfaceElevated)
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
    }
}
