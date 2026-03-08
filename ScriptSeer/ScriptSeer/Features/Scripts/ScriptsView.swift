import SwiftUI

struct ScriptsView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SSSpacing.md) {
                    SSEmptyState(
                        icon: "doc.text.magnifyingglass",
                        title: "Your Script Library",
                        subtitle: "Scripts you create or import will appear here.",
                        actionTitle: "Create Script"
                    ) {}
                }
                .padding(.top, SSSpacing.xxl)
            }
            .background(SSColors.background)
            .navigationTitle("Scripts")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search scripts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .foregroundStyle(SSColors.accent)
                    }
                }
            }
        }
    }
}
