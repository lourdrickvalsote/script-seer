import SwiftUI
import SwiftData

@main
struct ScriptSeerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSplash = true

    // Initialize services early
    private let remoteInput = RemoteInputService.shared
    private let settingsSync = SettingsSyncService.shared
    private let watchConnectivity = WatchConnectivityManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: SchemaV4.self)

        // Try CloudKit-enabled configuration first
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: ScriptSeerMigrationPlan.self,
                configurations: [cloudConfig]
            )
        } catch {
            // Fallback: local-only if CloudKit fails
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(
                    for: schema,
                    migrationPlan: ScriptSeerMigrationPlan.self,
                    configurations: [localConfig]
                )
            } catch {
                // Last resort: in-memory
                let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [fallback])
                } catch {
                    fatalError("Could not create ModelContainer: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if hasSeenOnboarding {
                        RootTabView()
                    } else {
                        OnboardingView()
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: hasSeenOnboarding)

                if showSplash {
                    SplashView {
                        withAnimation {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                // Route Watch actions through RemoteInputService
                watchConnectivity.onAction = { action in
                    remoteInput.dispatch(action)
                }
                // Push settings to iCloud on launch
                settingsSync.pushAll()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
