import SwiftUI

struct SSSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: SSSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SSColors.textTertiary)

            TextField(placeholder, text: $text)
                .font(SSTypography.body)
                .foregroundStyle(SSColors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SSColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, SSSpacing.sm)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: SSRadius.md)
                .fill(SSColors.surfaceElevated)
        )
        .shadow(color: SSColors.shadow, radius: 4, x: 0, y: 1)
    }
}
