import XCTest
@testable import MacLanguageSwitcher

final class ChordStateMachineTests: XCTestCase {
    func test_cleanLeftShiftAndLeftCommandChordTriggersOnRelease() {
        var state = ChordStateMachine()

        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftShiftKeyCode,
            isDown: true,
            modifierFlags: .maskShift
        ))
        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftCommandKeyCode,
            isDown: true,
            modifierFlags: [.maskShift, .maskCommand]
        ))

        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftShiftKeyCode,
            isDown: false,
            modifierFlags: .maskCommand
        ))
        XCTAssertTrue(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftCommandKeyCode,
            isDown: false,
            modifierFlags: []
        ))
    }

    func test_chordDisqualifiedWhenAnyOtherKeyPressed() {
        var state = ChordStateMachine()

        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftShiftKeyCode,
            isDown: true,
            modifierFlags: .maskShift
        ))
        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftCommandKeyCode,
            isDown: true,
            modifierFlags: [.maskShift, .maskCommand]
        ))

        XCTAssertFalse(state.handleKeyDown(keyCode: ChordStateMachine.spaceKeyCode))
        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftCommandKeyCode,
            isDown: false,
            modifierFlags: .maskShift
        ))
        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftShiftKeyCode,
            isDown: false,
            modifierFlags: []
        ))
    }

    func test_rightSideModifiersDoNotTriggerChord() {
        var state = ChordStateMachine()

        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.rightShiftKeyCode,
            isDown: true,
            modifierFlags: .maskShift
        ))
        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.rightCommandKeyCode,
            isDown: true,
            modifierFlags: [.maskShift, .maskCommand]
        ))
        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.rightShiftKeyCode,
            isDown: false,
            modifierFlags: .maskCommand
        ))
    }

    func test_shortSingleModifierTapDoesNotTriggerEvenIfCommandStateWasInconsistent() {
        var state = ChordStateMachine()

        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftCommandKeyCode,
            isDown: true,
            modifierFlags: .maskCommand
        ))

        // Simulate a fast-tap inconsistency: command release is observed with no command flag.
        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftCommandKeyCode,
            isDown: true,
            modifierFlags: []
        ))

        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftShiftKeyCode,
            isDown: true,
            modifierFlags: .maskShift
        ))
        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftShiftKeyCode,
            isDown: false,
            modifierFlags: []
        ))
    }

    func test_chordStillTriggersWhenIsDownSignalIsStaleButModifierFlagsAreCorrect() {
        var state = ChordStateMachine()

        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftShiftKeyCode,
            isDown: false,
            modifierFlags: .maskShift
        ))
        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftCommandKeyCode,
            isDown: false,
            modifierFlags: [.maskShift, .maskCommand]
        ))

        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftCommandKeyCode,
            isDown: false,
            modifierFlags: .maskShift
        ))
        XCTAssertTrue(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftShiftKeyCode,
            isDown: false,
            modifierFlags: []
        ))
    }

    func test_chordTriggersEvenWhenSecondModifierEventLacksFirstModifierFlag() {
        var state = ChordStateMachine()

        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftShiftKeyCode,
            isDown: true,
            modifierFlags: .maskShift
        ))

        // Real event streams can briefly provide only the changed modifier flag.
        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftCommandKeyCode,
            isDown: true,
            modifierFlags: .maskCommand
        ))

        XCTAssertFalse(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftCommandKeyCode,
            isDown: false,
            modifierFlags: .maskShift
        ))
        XCTAssertTrue(state.handleFlagsChanged(
            keyCode: ChordStateMachine.leftShiftKeyCode,
            isDown: false,
            modifierFlags: []
        ))
    }
}
