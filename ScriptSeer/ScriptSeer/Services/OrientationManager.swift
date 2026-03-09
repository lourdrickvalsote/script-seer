import UIKit

@Observable
final class OrientationManager {
    static let shared = OrientationManager()
    var allowsLandscape = false
    private init() {}
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationManager.shared.allowsLandscape ? .allButUpsideDown : .portrait
    }
}
