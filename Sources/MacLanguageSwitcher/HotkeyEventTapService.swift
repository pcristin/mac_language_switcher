import ApplicationServices
import Foundation

final class HotkeyEventTapService {
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
    private let emitter: ShortcutEmitter
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(emitter: ShortcutEmitter = ShortcutEmitter()) {
        self.emitter = emitter
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
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.eventSourceUserData) == ShortcutEmitter.syntheticEventTag {
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .flagsChanged:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            let isDown = CGEventSource.keyState(.combinedSessionState, key: keyCode)

            if stateMachine.handleFlagsChanged(keyCode: keyCode, isDown: isDown) {
                emitter.emitControlSpace()
            }
        case .keyDown:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            _ = stateMachine.handleKeyDown(keyCode: keyCode)
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
}
