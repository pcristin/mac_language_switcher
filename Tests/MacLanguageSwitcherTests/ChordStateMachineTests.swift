import XCTest
@testable import MacLanguageSwitcher

final class ChordStateMachineTests: XCTestCase {
    func test_cleanLeftShiftAndLeftCommandChordTriggersOnRelease() {
        var state = ChordStateMachine()

        XCTAssertFalse(state.handleFlagsChanged(keyCode: ChordStateMachine.leftShiftKeyCode, isDown: true))
        XCTAssertFalse(state.handleFlagsChanged(keyCode: ChordStateMachine.leftCommandKeyCode, isDown: true))

        XCTAssertTrue(state.handleFlagsChanged(keyCode: ChordStateMachine.leftShiftKeyCode, isDown: false))
    }

    func test_chordDisqualifiedWhenAnyOtherKeyPressed() {
        var state = ChordStateMachine()

        XCTAssertFalse(state.handleFlagsChanged(keyCode: ChordStateMachine.leftShiftKeyCode, isDown: true))
        XCTAssertFalse(state.handleFlagsChanged(keyCode: ChordStateMachine.leftCommandKeyCode, isDown: true))

        XCTAssertFalse(state.handleKeyDown(keyCode: ChordStateMachine.spaceKeyCode))
        XCTAssertFalse(state.handleFlagsChanged(keyCode: ChordStateMachine.leftCommandKeyCode, isDown: false))
    }

    func test_rightSideModifiersDoNotTriggerChord() {
        var state = ChordStateMachine()

        XCTAssertFalse(state.handleFlagsChanged(keyCode: ChordStateMachine.rightShiftKeyCode, isDown: true))
        XCTAssertFalse(state.handleFlagsChanged(keyCode: ChordStateMachine.rightCommandKeyCode, isDown: true))
        XCTAssertFalse(state.handleFlagsChanged(keyCode: ChordStateMachine.rightShiftKeyCode, isDown: false))
    }
}
