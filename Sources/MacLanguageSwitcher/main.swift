import Foundation

let service = HotkeyEventTapService()

do {
    try service.start()
    fputs("MacLanguageSwitcher is running. Press Ctrl+C to exit.\n", stderr)
    RunLoop.current.run()
} catch {
    fputs("Failed to start MacLanguageSwitcher: \(error.localizedDescription)\n", stderr)
    exit(1)
}
