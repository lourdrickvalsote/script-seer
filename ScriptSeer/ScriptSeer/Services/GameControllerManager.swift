import GameController
import Foundation

/// Manages game controller input for teleprompter control
@Observable
final class GameControllerManager {
    var isControllerConnected: Bool = false
    var controllerName: String = ""

    var onPlayPause: (() -> Void)?
    var onSpeedUp: (() -> Void)?
    var onSpeedDown: (() -> Void)?
    var onJumpBack: (() -> Void)?
    var onJumpForward: (() -> Void)?

    private var observers: [NSObjectProtocol] = []

    init() {
        setupNotifications()
        checkForControllers()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupNotifications() {
        let connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let controller = notification.object as? GCController {
                self?.configureController(controller)
            }
        }

        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isControllerConnected = false
            self?.controllerName = ""
        }

        observers = [connectObserver, disconnectObserver]
    }

    private func checkForControllers() {
        if let controller = GCController.controllers().first {
            configureController(controller)
        }
    }

    private func configureController(_ controller: GCController) {
        isControllerConnected = true
        controllerName = controller.vendorName ?? "Controller"

        // Extended gamepad (Xbox, PS, etc.)
        if let gamepad = controller.extendedGamepad {
            // A/Cross button = play/pause
            gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { DispatchQueue.main.async { self?.onPlayPause?() } }
            }
            // B/Circle button = jump back
            gamepad.buttonB.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { DispatchQueue.main.async { self?.onJumpBack?() } }
            }
            // Right shoulder = speed up
            gamepad.rightShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { DispatchQueue.main.async { self?.onSpeedUp?() } }
            }
            // Left shoulder = speed down
            gamepad.leftShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { DispatchQueue.main.async { self?.onSpeedDown?() } }
            }
            // D-pad left/right = jump back/forward
            gamepad.dpad.left.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { DispatchQueue.main.async { self?.onJumpBack?() } }
            }
            gamepad.dpad.right.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { DispatchQueue.main.async { self?.onJumpForward?() } }
            }
        }

        // Micro gamepad (Siri Remote, etc.)
        if let micro = controller.microGamepad {
            micro.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { DispatchQueue.main.async { self?.onPlayPause?() } }
            }
            micro.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { DispatchQueue.main.async { self?.onJumpBack?() } }
            }
        }
    }
}
