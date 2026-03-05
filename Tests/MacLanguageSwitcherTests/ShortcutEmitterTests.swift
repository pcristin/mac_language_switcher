import XCTest
@testable import MacLanguageSwitcher

final class ShortcutEmitterTests: XCTestCase {
    func test_emitterCreatesControlDownSpaceDownSpaceUpControlUpSequence() {
        let sequence = ShortcutEmitter.controlSpaceSequence()

        XCTAssertEqual(sequence.count, 4)
        XCTAssertEqual(sequence[0], KeyStroke(keyCode: ChordStateMachine.leftControlKeyCode, keyDown: true, flags: []))
        XCTAssertEqual(sequence[1], KeyStroke(keyCode: ChordStateMachine.spaceKeyCode, keyDown: true, flags: .maskControl))
        XCTAssertEqual(sequence[2], KeyStroke(keyCode: ChordStateMachine.spaceKeyCode, keyDown: false, flags: .maskControl))
        XCTAssertEqual(sequence[3], KeyStroke(keyCode: ChordStateMachine.leftControlKeyCode, keyDown: false, flags: []))
    }
}
