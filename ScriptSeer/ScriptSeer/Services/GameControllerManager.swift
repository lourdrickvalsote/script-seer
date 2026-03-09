import GameController
import Foundation

enum GamepadButton: String, CaseIterable, Codable {
    case buttonA
    case buttonB
    case buttonX
    case buttonY
    case leftShoulder
    case rightShoulder
    case dpadLeft
    case dpadRight
    case dpadUp
    case dpadDown

    var displayName: String {
        switch self {
        case .buttonA: "A / Cross"
        case .buttonB: "B / Circle"
        case .buttonX: "X / Square"
        case .buttonY: "Y / Triangle"
        case .leftShoulder: "Left Shoulder"
        case .rightShoulder: "Right Shoulder"
        case .dpadLeft: "D-Pad Left"
        case .dpadRight: "D-Pad Right"
        case .dpadUp: "D-Pad Up"
        case .dpadDown: "D-Pad Down"
        }
    }
}

@Observable
final class GameControllerManager {
    var isControllerConnected: Bool = false
    var controllerName: String = ""
    var onAction: ((RemoteAction) -> Void)?

    var buttonMapping: [GamepadButton: RemoteAction] = GameControllerManager.defaultMapping

    static let defaultMapping: [GamepadButton: RemoteAction] = [
        .buttonA: .playPause,
        .buttonB: .jumpBack,
        .rightShoulder: .speedUp,
        .leftShoulder: .speedDown,
        .dpadLeft: .jumpBack,
        .dpadRight: .jumpForward,
        .dpadUp: .speedUp,
        .dpadDown: .speedDown,
        .buttonX: .markStumble,
        .buttonY: .toggleRecording,
    ]

    private static let mappingKey = "gamepadButtonMapping"
    private var observers: [NSObjectProtocol] = []

    init() {
        loadMapping()
        setupNotifications()
        checkForControllers()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func saveMapping() {
        if let data = try? JSONEncoder().encode(buttonMapping) {
            UserDefaults.standard.set(data, forKey: Self.mappingKey)
        }
    }

    func resetMapping() {
        buttonMapping = Self.defaultMapping
        saveMapping()
    }

    private func loadMapping() {
        guard let data = UserDefaults.standard.data(forKey: Self.mappingKey),
              let mapping = try? JSONDecoder().decode([GamepadButton: RemoteAction].self, from: data) else { return }
        buttonMapping = mapping
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

    private func fire(_ button: GamepadButton) {
        guard let action = buttonMapping[button] else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onAction?(action)
        }
    }

    private func configureController(_ controller: GCController) {
        isControllerConnected = true
        controllerName = controller.vendorName ?? "Controller"

        if let gamepad = controller.extendedGamepad {
            gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.buttonA) }
            }
            gamepad.buttonB.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.buttonB) }
            }
            gamepad.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.buttonX) }
            }
            gamepad.buttonY.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.buttonY) }
            }
            gamepad.rightShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.rightShoulder) }
            }
            gamepad.leftShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.leftShoulder) }
            }
            gamepad.dpad.left.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.dpadLeft) }
            }
            gamepad.dpad.right.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.dpadRight) }
            }
            gamepad.dpad.up.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.dpadUp) }
            }
            gamepad.dpad.down.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.dpadDown) }
            }
        }

        if let micro = controller.microGamepad {
            micro.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.buttonA) }
            }
            micro.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.fire(.buttonX) }
            }
        }
    }
}
