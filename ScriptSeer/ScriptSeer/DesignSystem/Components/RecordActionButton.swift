import SwiftUI

struct RecordActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            SSHaptics.medium()
            action()
        }) {
            Image(systemName: "video.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(SSColors.accent)
                .clipShape(Circle())
                .shadow(color: SSColors.accent.opacity(0.5), radius: 16, x: 0, y: 4)
        }
        .buttonStyle(RecordActionButtonStyle())
    }
}

private struct RecordActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
