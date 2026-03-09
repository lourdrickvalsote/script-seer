import WatchConnectivity
import Foundation

@Observable
final class WatchSessionManager: NSObject {
    var scriptTitle: String?
    var activeMode: String?
    var progress: Double = 0
    var isPhoneReachable = false

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func sendAction(_ action: WatchRemoteAction) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["action": action.rawValue], replyHandler: nil)
    }
}

enum WatchRemoteAction: String {
    case playPause
    case nextLine
    case markStumble
    case jumpBack
    case jumpForward
    case toggleRecording
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isPhoneReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isPhoneReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.scriptTitle = applicationContext["scriptTitle"] as? String
            self?.activeMode = applicationContext["mode"] as? String
            self?.progress = applicationContext["progress"] as? Double ?? 0
        }
    }
}
