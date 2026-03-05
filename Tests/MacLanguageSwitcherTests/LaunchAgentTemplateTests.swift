import Foundation
import XCTest

final class LaunchAgentTemplateTests: XCTestCase {
    func test_launchAgentPlistContainsProgramPathPlaceholder() throws {
        let fileURL = URL(fileURLWithPath: #filePath)
        let packageRoot = fileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let plistURL = packageRoot
            .appendingPathComponent("launchd")
            .appendingPathComponent("com.mac-language-switcher.plist")

        let contents = try String(contentsOf: plistURL)
        XCTAssertTrue(contents.contains("__PROGRAM_PATH__"))
    }
}
