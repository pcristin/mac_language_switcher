import Foundation

struct RuntimeConfiguration {
    let debugEnabled: Bool

    init(arguments: [String], environment: [String: String]) {
        let flagEnabled = arguments.contains("--debug")
        let envEnabled = Self.boolFromEnv(environment["MLS_DEBUG"])
        debugEnabled = flagEnabled || envEnabled
    }

    private static func boolFromEnv(_ value: String?) -> Bool {
        guard let value else {
            return false
        }

        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "on":
            return true
        default:
            return false
        }
    }
}
