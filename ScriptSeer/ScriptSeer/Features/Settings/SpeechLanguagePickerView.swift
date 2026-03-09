import SwiftUI
import Speech

struct SpeechLanguagePickerView: View {
    @AppStorage("speechLanguage") private var speechLanguage = "auto"
    @Environment(\.dismiss) private var dismiss

    private var supportedLocales: [Locale] {
        SFSpeechRecognizer.supportedLocales()
            .sorted { lhs, rhs in
                let lhsName = lhs.localizedString(forIdentifier: lhs.identifier) ?? lhs.identifier
                let rhsName = rhs.localizedString(forIdentifier: rhs.identifier) ?? rhs.identifier
                return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
            }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Auto option
                Button {
                    speechLanguage = "auto"
                    dismiss()
                } label: {
                    languageRow(
                        title: "Auto (Device Language)",
                        subtitle: Locale.current.localizedString(forIdentifier: Locale.current.identifier),
                        isSelected: speechLanguage == "auto"
                    )
                }
                .buttonStyle(.plain)

                SettingsLanguageDivider()

                // All supported locales
                ForEach(supportedLocales, id: \.identifier) { locale in
                    Button {
                        speechLanguage = locale.identifier
                        dismiss()
                    } label: {
                        languageRow(
                            title: locale.localizedString(forIdentifier: locale.identifier) ?? locale.identifier,
                            subtitle: Locale.current.localizedString(forIdentifier: locale.identifier),
                            isSelected: speechLanguage == locale.identifier
                        )
                    }
                    .buttonStyle(.plain)

                    if locale.identifier != supportedLocales.last?.identifier {
                        SettingsLanguageDivider()
                    }
                }
            }
            .padding(.horizontal, SSSpacing.md)
            .padding(.vertical, SSSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: SSRadius.lg)
                    .fill(SSColors.surface)
            )
            .padding(.horizontal, SSSpacing.md)
            .padding(.top, SSSpacing.xs)
        }
        .background(SSColors.background)
        .navigationTitle("Speech Language")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func languageRow(title: String, subtitle: String?, isSelected: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SSTypography.body)
                    .foregroundStyle(SSColors.textPrimary)
                if let subtitle, subtitle != title {
                    Text(subtitle)
                        .font(SSTypography.caption)
                        .foregroundStyle(SSColors.textTertiary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SSColors.accent)
            }
        }
        .padding(.vertical, SSSpacing.sm)
        .padding(.horizontal, SSSpacing.xs)
        .contentShape(Rectangle())
    }
}

private struct SettingsLanguageDivider: View {
    var body: some View {
        Rectangle()
            .fill(SSColors.divider)
            .frame(height: 0.5)
    }
}
