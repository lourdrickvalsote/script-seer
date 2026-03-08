import SwiftUI

struct SSSectionHeader: View {
    let title: String
    let action: (() -> Void)?

    init(_ title: String, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(SSTypography.title2)
                .foregroundStyle(SSColors.textPrimary)

            Spacer()

            if let action {
                Button(action: action) {
                    Text("See All")
                        .font(SSTypography.subheadline)
                        .foregroundStyle(SSColors.accent)
                }
            }
        }
    }
}
