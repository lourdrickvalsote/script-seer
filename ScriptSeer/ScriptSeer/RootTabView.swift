import SwiftUI

// MARK: - Hide Record Button Preference

struct HideRecordButtonKey: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

struct RootTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showRecordView = false
    @State private var hideRecordButton = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        TabView(selection: Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab != .record {
                    selectedTab = newTab
                }
            }
        )) {
            ForEach(AppTab.allCases) { tab in
                tab.destination
                    .tabItem {
                        if tab == .record {
                            Label(horizontalSizeClass == .compact ? "" : "              ", systemImage: "")
                        } else {
                            Label(tab.title, systemImage: tab.icon)
                        }
                    }
                    .tag(tab)
            }
        }
        .tint(SSColors.accent)
        .ignoresSafeArea(.keyboard)
        .overlay(alignment: horizontalSizeClass == .compact ? .bottom : .top) {
            if !hideRecordButton {
                RecordActionButton {
                    showRecordView = true
                }
                .offset(y: horizontalSizeClass == .compact ? 20 : -14)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onPreferenceChange(HideRecordButtonKey.self) { hidden in
            withAnimation(SSAnimation.standard) {
                hideRecordButton = hidden
            }
        }
        .onAppear {
            configureTabBarAppearance()
        }
        .fullScreenCover(isPresented: $showRecordView) {
            RecordView()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(SSColors.surface)

        appearance.shadowColor = UIColor(SSColors.divider)

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
    case home, record, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .record: ""
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .record: ""
        case .settings: "gearshape.fill"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .home: HomeView()
        case .record: Color.clear
        case .settings: SettingsView()
        }
    }
}
