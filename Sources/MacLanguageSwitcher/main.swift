import Foundation

let config = RuntimeConfiguration(
    arguments: CommandLine.arguments,
    environment: ProcessInfo.processInfo.environment
)
let debugLogger = DebugLogger(enabled: config.debugEnabled)
let service = HotkeyEventTapService(debugLogger: debugLogger)

do {
    if config.debugEnabled {
        fputs("MacLanguageSwitcher debug mode enabled.\n", stderr)
    }
    try service.start()
    fputs("MacLanguageSwitcher is running. Press Ctrl+C to exit.\n", stderr)
    RunLoop.current.run()
} catch {
    fputs("Failed to start MacLanguageSwitcher: \(error.localizedDescription)\n", stderr)
    exit(1)
}
