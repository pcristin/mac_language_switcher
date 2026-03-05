import ApplicationServices
import Foundation

final class HotkeyEventTapService {
    private static let modifierReleasePollIntervalSeconds: TimeInterval = 0.005
    private static let modifierReleaseMaxAttempts = 8

    enum ServiceError: LocalizedError {
        case cannotCreateEventTap
        case cannotCreateRunLoopSource

        var errorDescription: String? {
            switch self {
            case .cannotCreateEventTap:
                return "Unable to create event tap. Grant Accessibility/Input Monitoring permissions."
            case .cannotCreateRunLoopSource:
                return "Unable to create run loop source for event tap."
            }
        }
    }

    private var stateMachine = ChordStateMachine()
    private let switcher: InputSourceSwitcher
    private let debugLogger: DebugLogger
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(
        switcher: InputSourceSwitcher = InputSourceSwitcher(),
        debugLogger: DebugLogger = .disabled
    ) {
        self.switcher = switcher
        self.debugLogger = debugLogger
    }

    func start() throws {
        let eventMask =
            (CGEventMask(1) << CGEventType.flagsChanged.rawValue) |
            (CGEventMask(1) << CGEventType.keyDown.rawValue)

        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: Self.eventTapCallback,
            userInfo: userInfo
        ) else {
            throw ServiceError.cannotCreateEventTap
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            throw ServiceError.cannotCreateRunLoopSource
        }

        eventTap = tap
        runLoopSource = source

        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        debugLogger.log("event tap started")
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
    }

    deinit {
        stop()
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            debugLogger.log("event tap re-enabled after \(type.rawValue)")
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .flagsChanged:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            let isDown = CGEventSource.keyState(.combinedSessionState, key: keyCode)
            let before = stateMachine.debugState

            let shouldEmit = stateMachine.handleFlagsChanged(
                keyCode: keyCode,
                isDown: isDown,
                modifierFlags: event.flags
            )

            debugLogger.log(
                "flagsChanged key=\(keyCode) isDown=\(isDown) flags=\(Self.formatFlags(event.flags)) " +
                    "before={\(before)} after={\(stateMachine.debugState)} trigger=\(shouldEmit)"
            )

            if shouldEmit {
                enqueueInputSourceSwitch()
            }
        case .keyDown:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            _ = stateMachine.handleKeyDown(keyCode: keyCode)
            debugLogger.log("keyDown key=\(keyCode) state={\(stateMachine.debugState)}")
        default:
            break
        }

        return Unmanaged.passUnretained(event)
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let service = Unmanaged<HotkeyEventTapService>.fromOpaque(userInfo).takeUnretainedValue()
        return service.handleEvent(type: type, event: event)
    }

    private func enqueueInputSourceSwitch() {
        debugLogger.log("queue switch input source")
        Self.switchWhenLeftModifiersReleased(
            switcher: switcher,
            debugLogger: debugLogger,
            attempt: 0
        )
    }

    private static func switchWhenLeftModifiersReleased(
        switcher: InputSourceSwitcher,
        debugLogger: DebugLogger,
        attempt: Int
    ) {
        let leftShiftDown = CGEventSource.keyState(.combinedSessionState, key: ChordStateMachine.leftShiftKeyCode)
        let leftCommandDown = CGEventSource.keyState(.combinedSessionState, key: ChordStateMachine.leftCommandKeyCode)

        if (leftShiftDown || leftCommandDown), attempt < modifierReleaseMaxAttempts {
            let intervalMs = Int(modifierReleasePollIntervalSeconds * 1000)
            debugLogger.log(
                "defer switch attempt=\(attempt) leftShiftDown=\(leftShiftDown) leftCommandDown=\(leftCommandDown) " +
                    "waitMs=\(intervalMs)"
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + modifierReleasePollIntervalSeconds) {
                Self.switchWhenLeftModifiersReleased(
                    switcher: switcher,
                    debugLogger: debugLogger,
                    attempt: attempt + 1
                )
            }
            return
        }

        let switched = switcher.cycleToNextSource()
        debugLogger.log(
            "switch input source attempt=\(attempt) leftShiftDown=\(leftShiftDown) " +
                "leftCommandDown=\(leftCommandDown) switched=\(switched)"
        )
    }

    private static func formatFlags(_ flags: CGEventFlags) -> String {
        let raw = flags.rawValue
        return "0x\(String(raw, radix: 16))"
    }
}
