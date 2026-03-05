#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY_NAME="MacLanguageSwitcher"
APP_DIR="$HOME/Library/Application Support/MacLanguageSwitcher"
BINARY_PATH="$APP_DIR/$BINARY_NAME"
PLIST_TEMPLATE="$ROOT_DIR/launchd/com.mac-language-switcher.plist"
PLIST_TARGET="$HOME/Library/LaunchAgents/com.mac-language-switcher.plist"
USER_DOMAIN="gui/$(id -u)"
DEBUG_MODE=0

for arg in "$@"; do
    case "$arg" in
        --debug)
            DEBUG_MODE=1
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            echo "Usage: $0 [--debug]" >&2
            exit 1
            ;;
    esac
done

echo "Building release binary..."
(cd "$ROOT_DIR" && swift build -c release)

mkdir -p "$APP_DIR" "$HOME/Library/LaunchAgents"
cp "$ROOT_DIR/.build/release/$BINARY_NAME" "$BINARY_PATH"
chmod +x "$BINARY_PATH"

sed "s|__PROGRAM_PATH__|$BINARY_PATH|g" "$PLIST_TEMPLATE" > "$PLIST_TARGET"

if [[ "$DEBUG_MODE" == "1" ]]; then
    plutil -insert EnvironmentVariables -json '{"MLS_DEBUG":"1"}' "$PLIST_TARGET" 2>/dev/null ||
        plutil -replace EnvironmentVariables -json '{"MLS_DEBUG":"1"}' "$PLIST_TARGET"
fi

launchctl bootout "$USER_DOMAIN" "$PLIST_TARGET" >/dev/null 2>&1 || true
launchctl bootstrap "$USER_DOMAIN" "$PLIST_TARGET"

cat <<MSG
Installed and started: $PLIST_TARGET

If this is the first run, grant permissions in System Settings:
- Privacy & Security -> Accessibility
- Privacy & Security -> Input Monitoring

Then restart service:
launchctl kickstart -k "$USER_DOMAIN/com.mac-language-switcher"
MSG

if [[ "$DEBUG_MODE" == "1" ]]; then
    echo "Debug mode enabled for LaunchAgent (MLS_DEBUG=1)."
    echo "Tail logs with: tail -f /tmp/mac-language-switcher.err.log"
fi
