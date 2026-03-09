import Foundation

@Observable
final class SettingsSyncService {
    static let shared = SettingsSyncService()

    private let kvStore = NSUbiquitousKeyValueStore.default

    // Keys that sync across devices
    private static let syncKeys: [String] = [
        "defaultScrollSpeed",
        "defaultTextSize",
        "defaultLineSpacing",
        "defaultCountdown",
        "speechFollowMode",
        "hapticsEnabled",
    ]

    private var observer: NSObjectProtocol?

    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore,
            queue: .main
        ) { [weak self] notification in
            self?.handleExternalChange(notification)
        }
        kvStore.synchronize()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    /// Push current UserDefaults values to iCloud KV store
    func pushAll() {
        let defaults = UserDefaults.standard
        for key in Self.syncKeys {
            if let value = defaults.object(forKey: key) {
                kvStore.set(value, forKey: key)
            }
        }
        kvStore.synchronize()
    }

    /// Push a single key to iCloud
    func push(_ key: String) {
        guard Self.syncKeys.contains(key) else { return }
        if let value = UserDefaults.standard.object(forKey: key) {
            kvStore.set(value, forKey: key)
            kvStore.synchronize()
        }
    }

    private func handleExternalChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else { return }

        // Only merge on server change or initial sync
        guard reason == NSUbiquitousKeyValueStoreServerChange ||
              reason == NSUbiquitousKeyValueStoreInitialSyncChange else { return }

        guard let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }

        let defaults = UserDefaults.standard
        for key in changedKeys where Self.syncKeys.contains(key) {
            if let value = kvStore.object(forKey: key) {
                defaults.set(value, forKey: key)
            }
        }
    }
}
