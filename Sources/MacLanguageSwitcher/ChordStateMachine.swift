import ApplicationServices

struct ChordStateMachine {
    static let leftCommandKeyCode: CGKeyCode = 55
    static let rightCommandKeyCode: CGKeyCode = 54
    static let leftShiftKeyCode: CGKeyCode = 56
    static let rightShiftKeyCode: CGKeyCode = 60
    static let leftControlKeyCode: CGKeyCode = 59
    static let rightControlKeyCode: CGKeyCode = 62
    static let leftOptionKeyCode: CGKeyCode = 58
    static let rightOptionKeyCode: CGKeyCode = 61
    static let spaceKeyCode: CGKeyCode = 49

    private var leftShiftDown = false
    private var leftCommandDown = false
    private var candidateActive = false
    private var disqualified = false

    mutating func handleFlagsChanged(
        keyCode: CGKeyCode,
        isDown: Bool,
        modifierFlags: CGEventFlags
    ) -> Bool {
        let effectiveIsDown = Self.effectiveModifierState(
            keyCode: keyCode,
            isDown: isDown,
            modifierFlags: modifierFlags
        )

        // Keep per-key state aligned with event flags to avoid stale-modifier false positives.
        if !modifierFlags.contains(.maskShift) {
            leftShiftDown = false
        }

        if !modifierFlags.contains(.maskCommand) {
            leftCommandDown = false
        }

        switch keyCode {
        case Self.leftShiftKeyCode:
            leftShiftDown = effectiveIsDown
        case Self.leftCommandKeyCode:
            leftCommandDown = effectiveIsDown
        case Self.rightShiftKeyCode,
             Self.rightCommandKeyCode,
             Self.leftControlKeyCode,
             Self.rightControlKeyCode,
             Self.leftOptionKeyCode,
             Self.rightOptionKeyCode:
            if candidateActive && effectiveIsDown {
                disqualified = true
            }
        default:
            break
        }

        let bothLeftModifiersDown = leftShiftDown && leftCommandDown

        if bothLeftModifiersDown && !candidateActive {
            candidateActive = true
            disqualified = false
        }

        if candidateActive && !bothLeftModifiersDown {
            let shouldTrigger = !disqualified
            candidateActive = false
            disqualified = false
            return shouldTrigger
        }

        return false
    }

    mutating func handleKeyDown(keyCode: CGKeyCode) -> Bool {
        if candidateActive && !Self.modifierKeyCodes.contains(keyCode) {
            disqualified = true
        }

        return false
    }

    private static let modifierKeyCodes: Set<CGKeyCode> = [
        leftCommandKeyCode,
        rightCommandKeyCode,
        leftShiftKeyCode,
        rightShiftKeyCode,
        leftControlKeyCode,
        rightControlKeyCode,
        leftOptionKeyCode,
        rightOptionKeyCode
    ]

    private static func effectiveModifierState(
        keyCode: CGKeyCode,
        isDown: Bool,
        modifierFlags: CGEventFlags
    ) -> Bool {
        guard let requiredFlag = modifierFlag(for: keyCode) else {
            return isDown
        }

        return modifierFlags.contains(requiredFlag)
    }

    private static func modifierFlag(for keyCode: CGKeyCode) -> CGEventFlags? {
        switch keyCode {
        case leftShiftKeyCode, rightShiftKeyCode:
            return .maskShift
        case leftCommandKeyCode, rightCommandKeyCode:
            return .maskCommand
        case leftControlKeyCode, rightControlKeyCode:
            return .maskControl
        case leftOptionKeyCode, rightOptionKeyCode:
            return .maskAlternate
        default:
            return nil
        }
    }
}
