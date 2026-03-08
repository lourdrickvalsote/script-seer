import SwiftUI

struct RecordView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SSEmptyState(
                    icon: "video.badge.waveform",
                    title: "Camera Recording",
                    subtitle: "Record yourself with your script overlaid near the lens for natural eye contact.",
                    actionTitle: "Select a Script"
                ) {}
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(SSColors.background)
            .navigationTitle("Record")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
