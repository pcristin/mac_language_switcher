import ApplicationServices

struct KeyStroke: Equatable {
    let keyCode: CGKeyCode
    let keyDown: Bool
    let flags: CGEventFlags
}

final class ShortcutEmitter {
    static let syntheticEventTag: Int64 = 0x4d4c53

    private let source: CGEventSource?

    init(source: CGEventSource? = CGEventSource(stateID: .hidSystemState)) {
        self.source = source
    }

    static func controlSpaceSequence() -> [KeyStroke] {
        [
            KeyStroke(keyCode: ChordStateMachine.leftControlKeyCode, keyDown: true, flags: []),
            KeyStroke(keyCode: ChordStateMachine.spaceKeyCode, keyDown: true, flags: .maskControl),
            KeyStroke(keyCode: ChordStateMachine.spaceKeyCode, keyDown: false, flags: .maskControl),
            KeyStroke(keyCode: ChordStateMachine.leftControlKeyCode, keyDown: false, flags: [])
        ]
    }

    func emitControlSpace() {
        guard let source else {
            return
        }

        for stroke in Self.controlSpaceSequence() {
            guard let event = CGEvent(
                keyboardEventSource: source,
                virtualKey: stroke.keyCode,
                keyDown: stroke.keyDown
            ) else {
                continue
            }

            event.flags = stroke.flags
            event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticEventTag)
            event.post(tap: .cghidEventTap)
        }
    }
}
