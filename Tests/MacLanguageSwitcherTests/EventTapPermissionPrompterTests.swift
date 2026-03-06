import XCTest
@testable import MacLanguageSwitcher

private final class FakeEventTapPermissionProvider: EventTapPermissionProviding {
    var preflightListenAccess = true
    var preflightAccessibilityTrustedValue = true
    var requestListenAccessCalls = 0
    var requestAccessibilityCalls = 0

    func preflightListenEventAccess() -> Bool {
        preflightListenAccess
    }

    func requestListenEventAccess() -> Bool {
        requestListenAccessCalls += 1
        return false
    }

    func preflightAccessibilityTrusted() -> Bool {
        preflightAccessibilityTrustedValue
    }

    func requestAccessibilityTrusted() -> Bool {
        requestAccessibilityCalls += 1
        return false
    }
}

final class EventTapPermissionPrompterTests: XCTestCase {
    func test_doesNotRequestWhenPermissionsAlreadyGranted() {
        let provider = FakeEventTapPermissionProvider()
        let prompter = EventTapPermissionPrompter(provider: provider)

        let result = prompter.requestMissingPermissions()

        XCTAssertFalse(result.requestedListenAccess)
        XCTAssertFalse(result.requestedAccessibility)
        XCTAssertEqual(provider.requestListenAccessCalls, 0)
        XCTAssertEqual(provider.requestAccessibilityCalls, 0)
    }

    func test_requestsOnlyListenAccessWhenMissing() {
        let provider = FakeEventTapPermissionProvider()
        provider.preflightListenAccess = false
        let prompter = EventTapPermissionPrompter(provider: provider)

        let result = prompter.requestMissingPermissions()

        XCTAssertTrue(result.requestedListenAccess)
        XCTAssertFalse(result.requestedAccessibility)
        XCTAssertEqual(provider.requestListenAccessCalls, 1)
        XCTAssertEqual(provider.requestAccessibilityCalls, 0)
    }

    func test_requestsOnlyAccessibilityWhenMissing() {
        let provider = FakeEventTapPermissionProvider()
        provider.preflightAccessibilityTrustedValue = false
        let prompter = EventTapPermissionPrompter(provider: provider)

        let result = prompter.requestMissingPermissions()

        XCTAssertFalse(result.requestedListenAccess)
        XCTAssertTrue(result.requestedAccessibility)
        XCTAssertEqual(provider.requestListenAccessCalls, 0)
        XCTAssertEqual(provider.requestAccessibilityCalls, 1)
    }

    func test_requestsBothPermissionsWhenBothMissing() {
        let provider = FakeEventTapPermissionProvider()
        provider.preflightListenAccess = false
        provider.preflightAccessibilityTrustedValue = false
        let prompter = EventTapPermissionPrompter(provider: provider)

        let result = prompter.requestMissingPermissions()

        XCTAssertTrue(result.requestedListenAccess)
        XCTAssertTrue(result.requestedAccessibility)
        XCTAssertEqual(provider.requestListenAccessCalls, 1)
        XCTAssertEqual(provider.requestAccessibilityCalls, 1)
    }
}
