import Foundation

struct DebugLogger: Sendable {
    static let disabled = DebugLogger(enabled: false)

    let enabled: Bool

    init(enabled: Bool) {
        self.enabled = enabled
    }

    func log(_ message: @autoclosure () -> String) {
        guard enabled else {
            return
        }

        let timestamp = String(format: "%.3f", Date().timeIntervalSince1970)
        fputs("[MLS DEBUG] \(timestamp) \(message())\n", stderr)
    }
}
