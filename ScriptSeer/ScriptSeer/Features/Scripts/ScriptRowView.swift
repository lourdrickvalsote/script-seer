import SwiftUI

struct ScriptRowView: View {
    let script: Script

    var body: some View {
        VStack(alignment: .leading, spacing: SSSpacing.xs) {
            Text(script.title)
                .font(SSTypography.headline)
                .foregroundStyle(SSColors.textPrimary)
                .lineLimit(1)

            HStack(spacing: SSSpacing.sm) {
                Label(script.formattedDuration, systemImage: "clock")
                Label("\(script.wordCount) words", systemImage: "text.word.spacing")
            }
            .font(SSTypography.caption)
            .foregroundStyle(SSColors.textTertiary)

            if !script.content.isEmpty {
                Text(script.content)
                    .font(SSTypography.footnote)
                    .foregroundStyle(SSColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, SSSpacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(script.title), \(script.wordCount) words, \(script.formattedDuration)")
    }
}
