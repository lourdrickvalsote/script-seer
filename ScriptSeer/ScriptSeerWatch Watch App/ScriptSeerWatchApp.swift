import SwiftUI

@main
struct ScriptSeerWatchApp: App {
    @State private var sessionManager = WatchSessionManager()

    var body: some Scene {
        WindowGroup {
            WatchRemoteView(sessionManager: sessionManager)
        }
    }
}
