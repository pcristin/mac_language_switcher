import Carbon.HIToolbox
import Foundation

protocol InputSourceProvider {
    func currentSourceID() -> String?
    func enabledSourceIDs() -> [String]
    func selectSource(id: String) -> Bool
}

struct InputSourceSwitchResult: Equatable, Sendable {
    let triggered: Bool
    let fromID: String?
    let targetID: String?
    let converged: Bool
    let selectAttempts: Int
}

final class InputSourceSwitcher: @unchecked Sendable {
    private static let maxSelectAttempts = 2
    private static let verificationAttempts = 3
    private static let verificationWaitSeconds: TimeInterval = 0.015
    private static let fallbackSleepMicroseconds: useconds_t = 8_000

    private let provider: InputSourceProvider
    private let selectionNotifier: InputSourceSelectionChangeNotifying

    init(
        provider: InputSourceProvider = TISInputSourceProvider(),
        selectionNotifier: InputSourceSelectionChangeNotifying = TISInputSourceSelectionChangeNotifier()
    ) {
        self.provider = provider
        self.selectionNotifier = selectionNotifier
    }

    @discardableResult
    func cycleToNextSource() -> InputSourceSwitchResult {
        let sourceIDs = provider.enabledSourceIDs()
        guard sourceIDs.count > 1 else {
            return InputSourceSwitchResult(
                triggered: false,
                fromID: provider.currentSourceID(),
                targetID: nil,
                converged: false,
                selectAttempts: 0
            )
        }

        let currentID = provider.currentSourceID()
        let nextID: String

        if let currentID, let currentIndex = sourceIDs.firstIndex(of: currentID) {
            nextID = sourceIDs[(currentIndex + 1) % sourceIDs.count]
        } else {
            nextID = sourceIDs[0]
        }

        if nextID == currentID {
            return InputSourceSwitchResult(
                triggered: false,
                fromID: currentID,
                targetID: nextID,
                converged: true,
                selectAttempts: 0
            )
        }

        var selectAttempts = 0
        for attempt in 1...Self.maxSelectAttempts {
            selectAttempts = attempt
            guard provider.selectSource(id: nextID) else {
                continue
            }

            if verifyConvergence(targetID: nextID) {
                return InputSourceSwitchResult(
                    triggered: true,
                    fromID: currentID,
                    targetID: nextID,
                    converged: true,
                    selectAttempts: attempt
                )
            }
        }

        return InputSourceSwitchResult(
            triggered: true,
            fromID: currentID,
            targetID: nextID,
            converged: provider.currentSourceID() == nextID,
            selectAttempts: selectAttempts
        )
    }

    private func verifyConvergence(targetID: String) -> Bool {
        if provider.currentSourceID() == targetID {
            return true
        }

        for _ in 0..<Self.verificationAttempts {
            if selectionNotifier.waitForSelectionChange(timeoutSeconds: Self.verificationWaitSeconds) {
                if provider.currentSourceID() == targetID {
                    return true
                }
                continue
            }

            usleep(Self.fallbackSleepMicroseconds)
            if provider.currentSourceID() == targetID {
                return true
            }
        }

        return provider.currentSourceID() == targetID
    }
}

final class TISInputSourceProvider: InputSourceProvider {
    func currentSourceID() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }

        return sourceID(from: source)
    }

    func enabledSourceIDs() -> [String] {
        let properties: [String: Any] = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as Any,
            kTISPropertyInputSourceIsSelectCapable as String: kCFBooleanTrue as Any,
            kTISPropertyInputSourceIsEnabled as String: kCFBooleanTrue as Any
        ]

        guard
            let list = TISCreateInputSourceList(properties as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource]
        else {
            return []
        }

        var ids: [String] = []
        ids.reserveCapacity(list.count)

        for source in list {
            guard let id = sourceID(from: source) else {
                continue
            }

            if !ids.contains(id) {
                ids.append(id)
            }
        }

        return ids
    }

    func selectSource(id: String) -> Bool {
        let properties = [kTISPropertyInputSourceID as String: id]

        guard
            let list = TISCreateInputSourceList(properties as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource],
            let source = list.first
        else {
            return false
        }

        return TISSelectInputSource(source) == noErr
    }

    private func sourceID(from source: TISInputSource) -> String? {
        guard let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }

        let value = unsafeBitCast(raw, to: CFTypeRef.self)
        return value as? String
    }
}
