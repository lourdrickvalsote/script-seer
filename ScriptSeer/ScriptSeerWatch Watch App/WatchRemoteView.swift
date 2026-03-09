import SwiftUI

struct WatchRemoteView: View {
    @State var sessionManager: WatchSessionManager

    var body: some View {
        VStack(spacing: 8) {
            if let title = sessionManager.scriptTitle {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let mode = sessionManager.activeMode {
                Text(mode)
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }

            Spacer()

            // Play / Pause
            Button {
                sessionManager.sendAction(.playPause)
            } label: {
                Image(systemName: "playpause.fill")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            HStack(spacing: 8) {
                // Next Line
                Button {
                    sessionManager.sendAction(.nextLine)
                } label: {
                    Image(systemName: "text.line.first.and.arrowtriangle.forward")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                // Mark Stumble
                Button {
                    sessionManager.sendAction(.markStumble)
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            if !sessionManager.isPhoneReachable {
                Text("iPhone not reachable")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 4)
        .navigationTitle("ScriptSeer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
