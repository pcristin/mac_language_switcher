import XCTest
@testable import MacLanguageSwitcher

final class RuntimeConfigurationTests: XCTestCase {
    func test_debugEnabledByCommandLineFlag() {
        let config = RuntimeConfiguration(
            arguments: ["MacLanguageSwitcher", "--debug"],
            environment: [:]
        )

        XCTAssertTrue(config.debugEnabled)
    }

    func test_debugEnabledByEnvironmentVariable() {
        let config = RuntimeConfiguration(
            arguments: ["MacLanguageSwitcher"],
            environment: ["MLS_DEBUG": "1"]
        )

        XCTAssertTrue(config.debugEnabled)
    }

    func test_debugDisabledByDefault() {
        let config = RuntimeConfiguration(
            arguments: ["MacLanguageSwitcher"],
            environment: [:]
        )

        XCTAssertFalse(config.debugEnabled)
    }
}
