import SwiftUI

struct SettingsView: View {
    @State private var store = StoreManager.shared
    @AppStorage("defaultScrollSpeed") private var defaultScrollSpeed = 40.0
    @AppStorage("defaultTextSize") private var defaultTextSize = 32.0
    @AppStorage("defaultLineSpacing") private var defaultLineSpacing = 16.0
    @AppStorage("defaultCountdown") private var defaultCountdown = 3
    @AppStorage("speechFollowMode") private var speechFollowMode = "Smart"

    private var defaultCountdownDouble: Binding<Double> {
        Binding(
            get: { Double(defaultCountdown) },
            set: { defaultCountdown = Int($0.rounded()) }
        )
    }
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private var aiStatus: AppleIntelligenceStatus { .current() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SSSpacing.lg) {
                    // Prompt Defaults
                    SettingsSection("Prompt Defaults") {
                        VStack(spacing: 0) {
                            SettingsSliderRow(
                                icon: "gauge.with.dots.needle.67percent",
                                title: "Scroll Speed",
                                value: $defaultScrollSpeed,
                                range: 10...120,
                                unit: "pt/s"
                            )

                            SettingsDivider()

                            SettingsSliderRow(
                                icon: "textformat.size",
                                title: "Text Size",
                                value: $defaultTextSize,
                                range: 18...72,
                                unit: "pt"
                            )

                            SettingsDivider()

                            SettingsSliderRow(
                                icon: "arrow.up.and.down.text.horizontal",
                                title: "Line Spacing",
                                value: $defaultLineSpacing,
                                range: 4...40,
                                unit: "pt"
                            )

                            SettingsDivider()

                            SettingsSliderRow(
                                icon: "timer",
                                title: "Countdown",
                                value: defaultCountdownDouble,
                                range: 0...10,
                                unit: "s"
                            )
                        }
                    }

                    // Speech Follow
                    SettingsSection("Speech Follow") {
                        HStack {
                            SettingsIconLabel(icon: "waveform", title: "Default Mode")
                            Spacer()
                            Picker("", selection: $speechFollowMode) {
                                Text("Strict").tag("Strict")
                                Text("Smart").tag("Smart")
                            }
                            .labelsHidden()
                            .tint(SSColors.accent)
                        }
                    }

                    // AI Actions
                    SettingsSection("AI Actions") {
                        HStack(spacing: SSSpacing.sm) {
                            Image(systemName: aiStatus.systemImage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(aiStatus.isAvailable ? SSColors.accent : SSColors.textTertiary)
                                .frame(width: 28, height: 28)
                                .background(SSColors.accentWarm)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Intelligence")
                                    .font(SSTypography.body)
                                    .foregroundStyle(SSColors.textPrimary)
                                Text(aiStatus.label)
                                    .font(SSTypography.caption)
                                    .foregroundStyle(aiStatus.isAvailable ? SSColors.accent : SSColors.textTertiary)
                            }

                            Spacer()
                        }
                    }

                    // General
                    SettingsSection("General") {
                        VStack(spacing: 0) {
                            HStack {
                                SettingsIconLabel(icon: "hand.tap", title: "Haptics")
                                Spacer()
                                Toggle("", isOn: $hapticsEnabled)
                                    .labelsHidden()
                                    .tint(SSColors.accent)
                            }

                            SettingsDivider()

                            Button {
                                hasSeenOnboarding = false
                                SSHaptics.light()
                            } label: {
                                HStack {
                                    SettingsIconLabel(icon: "arrow.counterclockwise", title: "Show Onboarding Tips")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(SSColors.textTertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Subscription
                    SettingsSection("Subscription") {
                        VStack(spacing: 0) {
                            NavigationLink(destination: ProUpgradeView()) {
                                HStack {
                                    SettingsIconLabel(icon: "star.fill", title: "ScriptSeer Pro")
                                    Spacer()
                                    if store.isProUser {
                                        Text("Active")
                                            .font(SSTypography.caption)
                                            .foregroundStyle(.green)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(SSColors.textTertiary)
                                }
                            }
                            .buttonStyle(.plain)

                            SettingsDivider()

                            Button {
                                Task { await store.restorePurchases() }
                            } label: {
                                HStack {
                                    SettingsIconLabel(icon: "arrow.clockwise", title: "Restore Purchases")
                                    Spacer()
                                    if store.isLoading {
                                        ProgressView()
                                            .tint(SSColors.accent)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(store.isLoading)
                        }
                    }

                    // About
                    SettingsSection("About") {
                        NavigationLink {
                            aboutView
                        } label: {
                            HStack {
                                SettingsIconLabel(icon: "info.circle", title: "About ScriptSeer")
                                Spacer()
                                Text(Bundle.main.appVersion)
                                    .font(SSTypography.caption)
                                    .foregroundStyle(SSColors.textTertiary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(SSColors.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer().frame(height: SSSpacing.md)
                }
                .padding(.horizontal, SSSpacing.md)
                .padding(.top, SSSpacing.xs)
            }
            .background(SSColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var aboutView: some View {
        ScrollView {
            VStack(spacing: SSSpacing.xl) {
                // Branded header matching splash
                HStack(spacing: 0) {
                    Text("Script")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(SSColors.textSecondary)
                    Text("Seer")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(SSColors.accent)
                }
                .padding(.top, SSSpacing.xxl)

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(SSColors.accent)

                VStack(spacing: SSSpacing.xs) {
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

// MARK: - Settings Section Card

private struct SettingsSection<Content: View>: View {
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

// MARK: - Settings Slider Row

private struct SettingsSliderRow: View {
    let icon: String
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(SSAnimation.standard) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    SettingsIconLabel(icon: icon, title: title)
                    Spacer()
                    Text("\(Int(value)) \(unit)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SSColors.accent)
                        .monospacedDigit()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SSColors.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Slider(value: $value, in: range)
                    .tint(SSColors.accent)
                    .padding(.top, SSSpacing.sm)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Settings Icon + Label

private struct SettingsIconLabel: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: SSSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SSColors.accent)
                .frame(width: 28, height: 28)
                .background(SSColors.accentWarm)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(SSTypography.body)
                .foregroundStyle(SSColors.textPrimary)
        }
    }
}

// MARK: - Settings Divider

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(SSColors.divider)
            .frame(height: 0.5)
            .padding(.vertical, SSSpacing.xs)
    }
}

private extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
}
