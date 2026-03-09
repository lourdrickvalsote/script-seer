import SwiftUI

struct ScriptSelectCard: View {
    let script: Script
    let icon: String

    var body: some View {
        SSCard {
            HStack(spacing: SSSpacing.sm) {
                VStack(alignment: .leading, spacing: SSSpacing.xxs) {
                    Text(script.title)
                        .font(SSTypography.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(SSColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: SSSpacing.xs) {
                        Text("\(script.wordCount) words")
                        Text("·")
                        Text(script.formattedDuration)
                    }
                    .font(SSTypography.caption)
                    .foregroundStyle(SSColors.textTertiary)

                    if !script.content.isEmpty {
                        Text(script.content)
                            .font(SSTypography.footnote)
                            .foregroundStyle(SSColors.textSecondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SSColors.accent)
                    .frame(width: 40, height: 40)
                    .background(SSColors.accentWarm)
                    .clipShape(Circle())
            }
        }
    }
}
