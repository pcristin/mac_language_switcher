import XCTest
@testable import MacLanguageSwitcher

private final class FakeInputSourceProvider: InputSourceProvider {
    var currentID: String?
    var ids: [String]
    var selectedIDs: [String] = []

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
        selectedIDs.append(id)
        currentID = id
        return true
    }
}

final class InputSourceSwitcherTests: XCTestCase {
    func test_cyclesToNextSource() {
        let provider = FakeInputSourceProvider(currentID: "en", ids: ["en", "ru"])
        let switcher = InputSourceSwitcher(provider: provider)

        XCTAssertTrue(switcher.cycleToNextSource())
        XCTAssertEqual(provider.selectedIDs, ["ru"])
    }

    func test_wrapsToFirstSource() {
        let provider = FakeInputSourceProvider(currentID: "ru", ids: ["en", "ru"])
        let switcher = InputSourceSwitcher(provider: provider)

        XCTAssertTrue(switcher.cycleToNextSource())
        XCTAssertEqual(provider.selectedIDs, ["en"])
    }

    func test_selectsFirstWhenCurrentIsMissing() {
        let provider = FakeInputSourceProvider(currentID: "de", ids: ["en", "ru"])
        let switcher = InputSourceSwitcher(provider: provider)

        XCTAssertTrue(switcher.cycleToNextSource())
        XCTAssertEqual(provider.selectedIDs, ["en"])
    }

    func test_doesNotSwitchWhenLessThanTwoSources() {
        let provider = FakeInputSourceProvider(currentID: "en", ids: ["en"])
        let switcher = InputSourceSwitcher(provider: provider)

        XCTAssertFalse(switcher.cycleToNextSource())
        XCTAssertTrue(provider.selectedIDs.isEmpty)
    }
}
