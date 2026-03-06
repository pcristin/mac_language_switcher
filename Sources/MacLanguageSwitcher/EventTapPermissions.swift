import ApplicationServices
import Foundation

struct EventTapPermissionRequestResult: Equatable, Sendable {
    let requestedListenAccess: Bool
    let requestedAccessibility: Bool
}

protocol EventTapPermissionProviding {
    func preflightListenEventAccess() -> Bool
    func requestListenEventAccess() -> Bool
    func preflightAccessibilityTrusted() -> Bool
    func requestAccessibilityTrusted() -> Bool
}

struct SystemEventTapPermissionProvider: EventTapPermissionProviding {
    func preflightListenEventAccess() -> Bool {
        CGPreflightListenEventAccess()
    }

    func requestListenEventAccess() -> Bool {
        CGRequestListenEventAccess()
    }

    func preflightAccessibilityTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityTrusted() -> Bool {
        let promptKey = "AXTrustedCheckOptionPrompt"
        let options = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}

struct EventTapPermissionPrompter {
    let provider: EventTapPermissionProviding

    init(provider: EventTapPermissionProviding = SystemEventTapPermissionProvider()) {
        self.provider = provider
    }

    func requestMissingPermissions() -> EventTapPermissionRequestResult {
        let requestedListenAccess: Bool
        if provider.preflightListenEventAccess() {
            requestedListenAccess = false
        } else {
            requestedListenAccess = true
            _ = provider.requestListenEventAccess()
        }

        let requestedAccessibility: Bool
        if provider.preflightAccessibilityTrusted() {
            requestedAccessibility = false
        } else {
            requestedAccessibility = true
            _ = provider.requestAccessibilityTrusted()
        }

        return EventTapPermissionRequestResult(
            requestedListenAccess: requestedListenAccess,
            requestedAccessibility: requestedAccessibility
        )
    }
}
