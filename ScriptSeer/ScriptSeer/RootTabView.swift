import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tab.destination
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .tint(SSColors.accent)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(SSColors.surface)

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = UIColor(SSColors.textTertiary)
        normal.titleTextAttributes = [.foregroundColor: UIColor(SSColors.textTertiary)]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = UIColor(SSColors.accent)
        selected.titleTextAttributes = [.foregroundColor: UIColor(SSColors.accent)]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case home, scripts, record, practice, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .scripts: "Scripts"
        case .record: "Record"
        case .practice: "Practice"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .scripts: "doc.text.fill"
        case .record: "video.fill"
        case .practice: "mic.fill"
        case .settings: "gearshape.fill"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .home: HomeView()
        case .scripts: ScriptsView()
        case .record: RecordView()
        case .practice: PracticeView()
        case .settings: SettingsView()
        }
    }
}
