import Carbon.HIToolbox
import Foundation

protocol InputSourceProvider {
    func currentSourceID() -> String?
    func enabledSourceIDs() -> [String]
    func selectSource(id: String) -> Bool
}

final class InputSourceSwitcher: @unchecked Sendable {
    private let provider: InputSourceProvider

    init(provider: InputSourceProvider = TISInputSourceProvider()) {
        self.provider = provider
    }

    @discardableResult
    func cycleToNextSource() -> Bool {
        let sourceIDs = provider.enabledSourceIDs()
        guard sourceIDs.count > 1 else {
            return false
        }

        let currentID = provider.currentSourceID()
        let nextID: String

        if let currentID, let currentIndex = sourceIDs.firstIndex(of: currentID) {
            nextID = sourceIDs[(currentIndex + 1) % sourceIDs.count]
        } else {
            nextID = sourceIDs[0]
        }

        if nextID == currentID {
            return false
        }

        return provider.selectSource(id: nextID)
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
