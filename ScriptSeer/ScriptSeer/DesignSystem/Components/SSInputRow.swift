import SwiftUI

struct SSInputRow: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    init(_ label: String, text: Binding<String>, placeholder: String = "") {
        self.label = label
        self._text = text
        self.placeholder = placeholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SSSpacing.xs) {
            Text(label)
                .font(SSTypography.footnote)
                .foregroundStyle(SSColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            TextField(placeholder, text: $text)
                .font(SSTypography.body)
                .foregroundStyle(SSColors.textPrimary)
                .padding(SSSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: SSRadius.sm)
                        .fill(SSColors.surfaceGlass)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SSRadius.sm)
                        .stroke(SSColors.divider, lineWidth: 0.5)
                )
        }
    }
}
