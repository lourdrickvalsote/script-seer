import WatchConnectivity
import Foundation

@Observable
final class WatchConnectivityManager: NSObject {
    static let shared = WatchConnectivityManager()

    private(set) var isWatchConnected = false
    private(set) var isWatchReachable = false
    private(set) var watchName: String = "Apple Watch"

    var onAction: ((RemoteAction) -> Void)?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Send current app state to Watch for context display
    func sendContext(scriptTitle: String, mode: String, progress: Double) {
        guard WCSession.default.isReachable else { return }
        let context: [String: Any] = [
            "scriptTitle": scriptTitle,
            "mode": mode,
            "progress": progress,
        ]
        try? WCSession.default.updateApplicationContext(context)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isWatchConnected = activationState == .activated && session.isPaired
            self?.isWatchReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isWatchReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let actionString = message["action"] as? String,
              let action = RemoteAction(rawValue: actionString) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onAction?(action)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let actionString = message["action"] as? String,
              let action = RemoteAction(rawValue: actionString) else {
            replyHandler(["status": "unknown_action"])
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.onAction?(action)
        }
        replyHandler(["status": "ok"])
    }
}
