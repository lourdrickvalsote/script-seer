import SwiftUI

struct SettingsView: View {
    @State private var store = StoreManager.shared
    @AppStorage("defaultScrollSpeed") private var defaultScrollSpeed = 40.0
    @AppStorage("defaultTextSize") private var defaultTextSize = 32.0
    @AppStorage("defaultLineSpacing") private var defaultLineSpacing = 16.0
    @AppStorage("defaultCountdown") private var defaultCountdown = 3
    @AppStorage("speechFollowMode") private var speechFollowMode = "Smart"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private var aiStatus: AppleIntelligenceStatus { .current() }

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

                // AI
                Section {
                    HStack(spacing: SSSpacing.sm) {
                        Image(systemName: aiStatus.systemImage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(aiStatus.isAvailable ? SSColors.accent : SSColors.textTertiary)
                            .frame(width: 28, height: 28)
                            .background(SSColors.accentSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Intelligence")
                                .font(SSTypography.body)
                                .foregroundStyle(SSColors.textPrimary)
                            Text(aiStatus.label)
                                .font(SSTypography.caption)
                                .foregroundStyle(aiStatus.isAvailable ? SSColors.accent : SSColors.textTertiary)
                        }
                    }
                    .padding(.vertical, SSSpacing.xxs)
                } header: {
                    Text("AI Actions")
                        .foregroundStyle(SSColors.textTertiary)
                } footer: {
                    if let detail = aiStatus.detail {
                        Text(detail)
                            .foregroundStyle(SSColors.textTertiary)
                    } else {
                        Text("AI actions use on-device Apple Intelligence. No data leaves your device.")
                            .foregroundStyle(SSColors.textTertiary)
                    }
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
                    Button(action: {
                        Task { await store.restorePurchases() }
                    }) {
                        HStack {
                            SettingsRow(icon: "arrow.clockwise", title: "Restore Purchases")
                            if store.isLoading {
                                Spacer()
                                ProgressView()
                                    .tint(SSColors.accent)
                            }
                        }
                    }
                    .disabled(store.isLoading)
                } header: {
                    Text("Subscription")
                        .foregroundStyle(SSColors.textTertiary)
                }
                .listRowBackground(SSColors.surfaceElevated)

                // About
                Section {
                    NavigationLink {
                        aboutView
                    } label: {
                        HStack {
                            SettingsRow(icon: "info.circle", title: "About ScriptSeer")
                            Spacer()
                            Text(Bundle.main.appVersion)
                                .font(SSTypography.caption)
                                .foregroundStyle(SSColors.textTertiary)
                        }
                    }
                } header: {
                    Text("More")
                        .foregroundStyle(SSColors.textTertiary)
                }
                .listRowBackground(SSColors.surfaceElevated)
            }
            .scrollContentBackground(.hidden)
            .background(SSColors.background)
            .navigationTitle("Settings")
        }
    }

    private var aboutView: some View {
        ScrollView {
            VStack(spacing: SSSpacing.xl) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(SSColors.accent)
                    .padding(.top, SSSpacing.xxl)

                VStack(spacing: SSSpacing.xs) {
                    Text("ScriptSeer")
                        .font(SSTypography.largeTitle)
                        .foregroundStyle(SSColors.textPrimary)

                    Text(Bundle.main.appVersion)
                        .font(SSTypography.subheadline)
                        .foregroundStyle(SSColors.textTertiary)
                }

                Text("A premium teleprompter for creators, speakers, and storytellers.")
                    .font(SSTypography.body)
                    .foregroundStyle(SSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SSSpacing.xl)
            }
        }
        .background(SSColors.background)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
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
