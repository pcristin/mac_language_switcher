# Mac Language Switcher

Personal macOS utility that cycles input sources with `Left Shift + Left Command` while preserving existing shortcut behavior.

## What it does

- Detects `LShift + LCommand` chord.
- Triggers only when both are pressed and released without any other key.
- Switches to the next enabled keyboard input source using macOS Text Input Source APIs.
- Passes through all original keyboard events, so other shortcuts stay unchanged.

## Limitations

- Requires macOS permissions (`Accessibility` and `Input Monitoring`).
- Secure input contexts may block event taps.
- If Keychron mode changes device identity (wired/Bluetooth), behavior still works if events reach macOS HID layer.

## Build

```bash
swift build -c release
```

## Run manually

```bash
swift run MacLanguageSwitcher
```

Debug run:

```bash
swift run MacLanguageSwitcher --debug
```

## Install as login service

```bash
./scripts/install-launch-agent.sh
```

Install with debug logs enabled:

```bash
./scripts/install-launch-agent.sh --debug
```

LaunchAgent file:
- `launchd/com.mac-language-switcher.plist`

## Service control

```bash
launchctl kickstart -k "gui/$(id -u)/com.mac-language-switcher"
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.mac-language-switcher.plist"
```

## Makefile shortcuts

```bash
make test
make install
make install-debug
make restart
make reinstall
make uninstall
make status
make logs
```

## Debug logs

- Runtime debug mode is enabled via `--debug` or `MLS_DEBUG=1`.
- LaunchAgent debug mode is enabled by `./scripts/install-launch-agent.sh --debug`.
- Logs are written to:
  - `/tmp/mac-language-switcher.err.log`
  - `/tmp/mac-language-switcher.log`

## Permission automation

macOS does not allow programmatic granting of Accessibility/Input Monitoring (TCC) permissions.
The app explicitly requests both permissions on startup when they are missing, but macOS may not show the UI reliably for background LaunchAgent processes.
You must grant them manually in:
- `System Settings -> Privacy & Security -> Accessibility`
- `System Settings -> Privacy & Security -> Input Monitoring`

If no permission prompt appears after `make install-debug`, run once in foreground to force request flow:

```bash
swift run MacLanguageSwitcher --debug
```

## Verification checklist

1. Run `swift test`.
2. Run `swift build -c release`.
3. Start the utility and verify `LShift + LCommand` cycles input source.
4. Verify shortcuts like `Cmd + Shift + T` still work exactly as before.
5. Verify behavior with built-in keyboard and Keychron K3v3.
