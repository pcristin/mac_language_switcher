import XCTest
@testable import MacLanguageSwitcher

private final class FakeInputSourceProvider: InputSourceProvider {
    var currentID: String?
    var ids: [String]
    var selectedIDs: [String] = []
    var selectResults: [Bool] = []
    var applySelectionOnAttempts: Set<Int> = [1]
    private var selectCallCount = 0

    init(currentID: String?, ids: [String]) {
        self.currentID = currentID
        self.ids = ids
    }

    func currentSourceID() -> String? {
        currentID
    }

    func enabledSourceIDs() -> [String] {
        ids
    }

    func selectSource(id: String) -> Bool {
        selectCallCount += 1
        selectedIDs.append(id)
        let result = selectResults.indices.contains(selectCallCount - 1) ? selectResults[selectCallCount - 1] : true
        if result, applySelectionOnAttempts.contains(selectCallCount) {
            currentID = id
        }
        return result
    }
}

private final class FakeInputSourceSelectionChangeNotifier: InputSourceSelectionChangeNotifying, @unchecked Sendable {
    var waitResults: [Bool] = []
    var waitCallCount = 0
    var onWait: ((Int) -> Void)?

    func waitForSelectionChange(timeoutSeconds: TimeInterval) -> Bool {
        waitCallCount += 1
        onWait?(waitCallCount)
        return waitResults.indices.contains(waitCallCount - 1) ? waitResults[waitCallCount - 1] : false
    }
}

final class InputSourceSwitcherTests: XCTestCase {
    func test_cyclesToNextSourceAndConvergesImmediately() {
        let provider = FakeInputSourceProvider(currentID: "en", ids: ["en", "ru"])
        let notifier = FakeInputSourceSelectionChangeNotifier()
        let switcher = InputSourceSwitcher(provider: provider, selectionNotifier: notifier)

        let result = switcher.cycleToNextSource()

        XCTAssertTrue(result.triggered)
        XCTAssertEqual(result.fromID, "en")
        XCTAssertEqual(result.targetID, "ru")
        XCTAssertTrue(result.converged)
        XCTAssertEqual(result.selectAttempts, 1)
        XCTAssertEqual(provider.selectedIDs, ["ru"])
        XCTAssertEqual(notifier.waitCallCount, 0)
    }

    func test_wrapsToFirstSource() {
        let provider = FakeInputSourceProvider(currentID: "ru", ids: ["en", "ru"])
        let switcher = InputSourceSwitcher(provider: provider)

        let result = switcher.cycleToNextSource()
        XCTAssertTrue(result.triggered)
        XCTAssertEqual(result.targetID, "en")
        XCTAssertTrue(result.converged)
        XCTAssertEqual(provider.selectedIDs, ["en"])
    }

    func test_selectsFirstWhenCurrentIsMissing() {
        let provider = FakeInputSourceProvider(currentID: "de", ids: ["en", "ru"])
        let switcher = InputSourceSwitcher(provider: provider)

        let result = switcher.cycleToNextSource()
        XCTAssertTrue(result.triggered)
        XCTAssertEqual(result.targetID, "en")
        XCTAssertEqual(provider.selectedIDs, ["en"])
    }

    func test_doesNotSwitchWhenLessThanTwoSources() {
        let provider = FakeInputSourceProvider(currentID: "en", ids: ["en"])
        let switcher = InputSourceSwitcher(provider: provider)

        let result = switcher.cycleToNextSource()
        XCTAssertFalse(result.triggered)
        XCTAssertEqual(result.selectAttempts, 0)
        XCTAssertTrue(provider.selectedIDs.isEmpty)
    }

    func test_retriesSelectionWhenCurrentDoesNotMoveInitially() {
        let provider = FakeInputSourceProvider(currentID: "en", ids: ["en", "ru"])
        provider.applySelectionOnAttempts = [2]
        let notifier = FakeInputSourceSelectionChangeNotifier()
        let switcher = InputSourceSwitcher(provider: provider, selectionNotifier: notifier)

        let result = switcher.cycleToNextSource()

        XCTAssertTrue(result.triggered)
        XCTAssertTrue(result.converged)
        XCTAssertEqual(result.selectAttempts, 2)
        XCTAssertEqual(provider.selectedIDs, ["ru", "ru"])
    }

    func test_reportsNonConvergedWhenSelectionNeverTakesEffect() {
        let provider = FakeInputSourceProvider(currentID: "en", ids: ["en", "ru"])
        provider.applySelectionOnAttempts = []
        let notifier = FakeInputSourceSelectionChangeNotifier()
        notifier.waitResults = [false, false, false, false, false, false]
        let switcher = InputSourceSwitcher(provider: provider, selectionNotifier: notifier)

        let result = switcher.cycleToNextSource()

        XCTAssertTrue(result.triggered)
        XCTAssertFalse(result.converged)
        XCTAssertEqual(result.selectAttempts, 2)
        XCTAssertEqual(result.fromID, "en")
        XCTAssertEqual(result.targetID, "ru")
    }

    func test_usesNotificationWaitToObserveSelectionChange() {
        let provider = FakeInputSourceProvider(currentID: "en", ids: ["en", "ru"])
        provider.applySelectionOnAttempts = []
        let notifier = FakeInputSourceSelectionChangeNotifier()
        notifier.waitResults = [true]
        notifier.onWait = { _ in
            provider.currentID = "ru"
        }
        let switcher = InputSourceSwitcher(provider: provider, selectionNotifier: notifier)

        let result = switcher.cycleToNextSource()

        XCTAssertTrue(result.triggered)
        XCTAssertTrue(result.converged)
        XCTAssertEqual(result.selectAttempts, 1)
        XCTAssertEqual(notifier.waitCallCount, 1)
    }
}
