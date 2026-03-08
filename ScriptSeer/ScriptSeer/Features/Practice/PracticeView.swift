import SwiftUI

struct PracticeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                SSEmptyState(
                    icon: "mic.badge.xmark",
                    title: "Practice Mode",
                    subtitle: "Rehearse your script and get feedback on pacing and stumbles — no recording needed.",
                    actionTitle: "Select a Script"
                ) {}
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(SSColors.background)
            .navigationTitle("Practice")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
