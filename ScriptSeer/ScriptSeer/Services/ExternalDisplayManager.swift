import UIKit
import SwiftUI

/// Manages external display (AirPlay/HDMI) for teleprompter output
@Observable
final class ExternalDisplayManager {
    var isExternalDisplayConnected: Bool = false
    var isExternalOutputEnabled: Bool = false
    var independentMirror: Bool = false
    var externalWindow: UIWindow?

    private var screenObservers: [NSObjectProtocol] = []

    init() {
        checkForExternalDisplay()
        setupNotifications()
    }

    deinit {
        for observer in screenObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        disconnectExternalDisplay()
    }

    private func setupNotifications() {
        let connectObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.didConnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let screen = notification.object as? UIScreen else { return }
            self?.connectExternalDisplay(screen: screen)
        }

        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.disconnectExternalDisplay()
        }

        screenObservers = [connectObserver, disconnectObserver]
    }

    private func checkForExternalDisplay() {
        let screens = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.session.role == .windowExternalDisplayNonInteractive }

        if let externalScene = screens.first {
            isExternalDisplayConnected = true
            setupWindowForScene(externalScene)
        }
    }

    private func connectExternalDisplay(screen: UIScreen) {
        isExternalDisplayConnected = true
        checkForExternalDisplay()
    }

    private func disconnectExternalDisplay() {
        externalWindow?.isHidden = true
        externalWindow = nil
        isExternalDisplayConnected = false
    }

    /// Show teleprompter content on external display
    func showOnExternalDisplay<Content: View>(_ content: Content) {
        guard isExternalDisplayConnected else { return }

        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.session.role == .windowExternalDisplayNonInteractive }

        guard let externalScene = scenes.first else { return }
        setupWindowForScene(externalScene)

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .black
        externalWindow?.rootViewController = hostingController
        externalWindow?.isHidden = false
    }

    private func setupWindowForScene(_ scene: UIWindowScene) {
        if externalWindow == nil {
            let window = UIWindow(windowScene: scene)
            window.isHidden = false
            externalWindow = window
        }
    }

    /// Show teleprompter on external display synced to a prompt session
    func showTeleprompter(session: PromptSession) {
        let view = ExternalPromptView(session: session, externalDisplay: self)
        showOnExternalDisplay(view)
    }

    /// Dismiss external display content
    func dismissExternalDisplay() {
        externalWindow?.rootViewController = nil
        externalWindow?.isHidden = true
    }
}
