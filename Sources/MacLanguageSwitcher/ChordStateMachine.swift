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
    private var rightShiftDown = false
    private var rightCommandDown = false
    private var leftControlDown = false
    private var rightControlDown = false
    private var leftOptionDown = false
    private var rightOptionDown = false
    private var candidateActive = false
    private var disqualified = false

    mutating func handleFlagsChanged(
        keyCode: CGKeyCode,
        isDown _: Bool,
        modifierFlags: CGEventFlags
    ) -> Bool {
        switch keyCode {
        case Self.leftShiftKeyCode:
            leftShiftDown = Self.changedKeyIsPressed(
                priorState: leftShiftDown,
                aggregateFlagIsSet: modifierFlags.contains(.maskShift)
            )
        case Self.leftCommandKeyCode:
            leftCommandDown = Self.changedKeyIsPressed(
                priorState: leftCommandDown,
                aggregateFlagIsSet: modifierFlags.contains(.maskCommand)
            )
        case Self.rightShiftKeyCode:
            rightShiftDown = Self.changedKeyIsPressed(
                priorState: rightShiftDown,
                aggregateFlagIsSet: modifierFlags.contains(.maskShift)
            )
            if candidateActive && rightShiftDown {
                disqualified = true
            }
        case Self.rightCommandKeyCode:
            rightCommandDown = Self.changedKeyIsPressed(
                priorState: rightCommandDown,
                aggregateFlagIsSet: modifierFlags.contains(.maskCommand)
            )
            if candidateActive && rightCommandDown {
                disqualified = true
            }
        case Self.leftControlKeyCode:
            leftControlDown = Self.changedKeyIsPressed(
                priorState: leftControlDown,
                aggregateFlagIsSet: modifierFlags.contains(.maskControl)
            )
            if candidateActive && leftControlDown {
                disqualified = true
            }
        case Self.rightControlKeyCode:
            rightControlDown = Self.changedKeyIsPressed(
                priorState: rightControlDown,
                aggregateFlagIsSet: modifierFlags.contains(.maskControl)
            )
            if candidateActive && rightControlDown {
                disqualified = true
            }
        case Self.leftOptionKeyCode:
            leftOptionDown = Self.changedKeyIsPressed(
                priorState: leftOptionDown,
                aggregateFlagIsSet: modifierFlags.contains(.maskAlternate)
            )
            if candidateActive && leftOptionDown {
                disqualified = true
            }
        case Self.rightOptionKeyCode:
            rightOptionDown = Self.changedKeyIsPressed(
                priorState: rightOptionDown,
                aggregateFlagIsSet: modifierFlags.contains(.maskAlternate)
            )
            if candidateActive && rightOptionDown {
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

    private static func changedKeyIsPressed(
        priorState: Bool,
        aggregateFlagIsSet: Bool
    ) -> Bool {
        if priorState {
            // The key that generated this flagsChanged event was previously down, so it just released.
            return false
        }

        return aggregateFlagIsSet
    }
}
