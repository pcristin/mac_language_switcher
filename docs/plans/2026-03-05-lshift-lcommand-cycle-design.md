# LShift+LCommand Input Source Cycler Design

## Goal

Build a personal macOS background utility that triggers the same input-source cycling behavior as `Control+Space` when the user presses and releases `Left Shift + Left Command` together, while preserving all existing keyboard shortcut behavior.

## Requirements

- Trigger only for `left_shift + left_command`.
- Trigger only when both modifier keys were pressed together and released without any other key press.
- Preserve all existing shortcuts and modifier behavior (`Cmd+Shift+T`, etc.).
- Match current macOS input-source cycling behavior by delegating to the same system shortcut path.
- Work for both built-in keyboard and external keyboards (including Keychron K3v3) as long as events reach macOS at HID level.

## Approaches Considered

1. Remapper configuration (Karabiner-Elements).
   - Pros: fast setup, stable.
   - Cons: external dependency, not an in-house utility.
2. Direct input-source API cycling (`TISSelectInputSource`).
   - Pros: fully custom.
   - Cons: can diverge from exact `Control+Space` order/behavior and may require extra logic for source ordering.
3. Custom event-tap utility that synthesizes `Control+Space`.
   - Pros: in-house code and exact system behavior because macOS executes the existing shortcut path.
   - Cons: requires Accessibility/Input Monitoring permission.

## Chosen Design

Use a Swift background process with a global `CGEventTap` that listens to keyboard events, detects the `Left Shift + Left Command` chord, and posts synthetic `Control+Space` keyboard events when the chord is released cleanly.

## Architecture

- `AppEntry`: starts run loop and the hotkey service.
- `HotkeyService`: owns event tap lifecycle and callback.
- `ChordState`: tracks key states and qualification rules.
- `ShortcutEmitter`: posts synthetic keyboard events (`Ctrl down`, `Space down/up`, `Ctrl up`).

## Data Flow

1. Event tap receives `flagsChanged` and `keyDown`.
2. `ChordState` updates `leftShiftDown`/`leftCommandDown` from keycodes.
3. When both are down, start a candidate chord.
4. Any non-modifier `keyDown` (or disallowed modifier) marks candidate as disqualified.
5. On first release of either left modifier:
   - if candidate is still qualified, emit `Control+Space`;
   - reset candidate state.
6. All original events continue through the system unchanged.

## Compatibility Notes

- Left-only detection uses physical keycodes (`55` left command, `56` left shift, plus right-side codes for disqualification checks).
- Works across built-in/external keyboards if keycodes are standard HID usage translations as exposed by macOS event system.
- Does not alter secure input contexts where event taps are restricted by the OS.

## Error Handling

- On permission or tap-creation failure, log explicit startup error and exit non-zero.
- If event tap is disabled by timeout/user input, auto-reenable when possible and log status.

## Testing Strategy

- Unit tests for chord state machine:
  - clean chord release triggers action;
  - chord with extra key press does not trigger;
  - right-side modifiers do not trigger.
- Manual validation on macOS:
  - verify `Cmd+Shift+<key>` shortcuts remain unchanged;
  - verify language cycling order matches existing `Ctrl+Space`;
  - verify behavior with built-in keyboard and Keychron K3v3 (wired/Bluetooth modes if used).

## Security and Privacy

- Utility only processes keyboard event metadata needed for hotkey detection.
- No persistence of keystroke content.
- No network access required.
