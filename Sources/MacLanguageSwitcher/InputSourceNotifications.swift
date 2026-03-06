import Carbon.HIToolbox
import Foundation

protocol InputSourceSelectionChangeNotifying: Sendable {
    func waitForSelectionChange(timeoutSeconds: TimeInterval) -> Bool
}

struct TISInputSourceSelectionChangeNotifier: InputSourceSelectionChangeNotifying {
    func waitForSelectionChange(timeoutSeconds: TimeInterval) -> Bool {
        guard timeoutSeconds > 0 else {
            return false
        }

        let semaphore = DispatchSemaphore(value: 0)
        let name = Notification.Name(rawValue: kTISNotifySelectedKeyboardInputSourceChanged as String)
        let center = DistributedNotificationCenter.default()
        let observer = center.addObserver(forName: name, object: nil, queue: nil) { _ in
            semaphore.signal()
        }

        defer {
            center.removeObserver(observer)
        }

        return semaphore.wait(timeout: .now() + timeoutSeconds) == .success
    }
}
