# Mac Language Switcher

Personal macOS utility that cycles input sources with `Left Shift + Left Command` while preserving existing shortcut behavior.

## What it does

- Detects `LShift + LCommand` chord.
- Triggers only when both are pressed and released without any other key.
- Emits synthetic `Ctrl + Space`, so macOS performs the same input-source cycle logic/order as your current shortcut.
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

## Install as login service

```bash
./scripts/install-launch-agent.sh
```

LaunchAgent file:
- `launchd/com.mac-language-switcher.plist`

## Service control

```bash
launchctl kickstart -k "gui/$(id -u)/com.mac-language-switcher"
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.mac-language-switcher.plist"
```

## Verification checklist

1. Run `swift test`.
2. Run `swift build -c release`.
3. Start the utility and verify `LShift + LCommand` cycles input source.
4. Verify shortcuts like `Cmd + Shift + T` still work exactly as before.
5. Verify behavior with built-in keyboard and Keychron K3v3.
