import Foundation

@Observable
final class RemoteInputService {
    static let shared = RemoteInputService()

    private(set) var gameController = GameControllerManager()
    private(set) var latestAction: (action: RemoteAction, id: UUID)?

    var isControllerConnected: Bool { gameController.isControllerConnected }
    var controllerName: String { gameController.controllerName }

    private init() {
        gameController.onAction = { [weak self] action in
            self?.dispatch(action)
        }
    }

    func dispatch(_ action: RemoteAction) {
        latestAction = (action: action, id: UUID())
    }
}
