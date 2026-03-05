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

    mutating func handleFlagsChanged(keyCode: CGKeyCode, isDown: Bool) -> Bool {
        switch keyCode {
        case Self.leftShiftKeyCode:
            leftShiftDown = isDown
        case Self.leftCommandKeyCode:
            leftCommandDown = isDown
        case Self.rightShiftKeyCode,
             Self.rightCommandKeyCode,
             Self.leftControlKeyCode,
             Self.rightControlKeyCode,
             Self.leftOptionKeyCode,
             Self.rightOptionKeyCode:
            if candidateActive && isDown {
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
}
