# LShift+LCommand Input Source Cycler Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a macOS background utility that cycles input sources exactly like `Control+Space` when `Left Shift + Left Command` is pressed and released alone.

**Architecture:** A Swift executable runs a global event tap and a small chord state machine. When a valid chord completes, it emits synthetic `Control+Space` keyboard events through `CGEvent` so macOS performs native input-source switching logic.

**Tech Stack:** Swift 6, Swift Package Manager, CoreGraphics/ApplicationServices, XCTest, LaunchAgent plist.

---

### Task 1: Scaffold Swift package and app entrypoint

**Files:**
- Create: `Package.swift`
- Create: `Sources/MacLanguageSwitcher/main.swift`
- Create: `README.md`

**Step 1: Write the failing test**

Create `Tests/MacLanguageSwitcherTests/BuildSmokeTests.swift`:

```swift
import XCTest

final class BuildSmokeTests: XCTestCase {
    func test_placeholder() {
        XCTAssertTrue(true)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test`
Expected: FAIL because package/source layout does not exist yet.

**Step 3: Write minimal implementation**

Create `Package.swift` with executable + test target, and `main.swift` with a run loop placeholder:

```swift
import Foundation

print("MacLanguageSwitcher starting...")
RunLoop.current.run()
```

Add `README.md` with build/run basics.

**Step 4: Run test to verify it passes**

Run: `swift test`
Expected: PASS for `BuildSmokeTests`.

**Step 5: Commit**

```bash
git add Package.swift Sources/MacLanguageSwitcher/main.swift Tests/MacLanguageSwitcherTests/BuildSmokeTests.swift README.md
git commit -m "chore: scaffold mac language switcher package"
```

### Task 2: Implement chord state machine with TDD

**Files:**
- Create: `Sources/MacLanguageSwitcher/ChordStateMachine.swift`
- Create: `Tests/MacLanguageSwitcherTests/ChordStateMachineTests.swift`
- Modify: `Sources/MacLanguageSwitcher/main.swift`

**Step 1: Write the failing test**

Create tests for transitions:

```swift
func test_cleanLeftShiftAndLeftCommandChordTriggersOnRelease()
func test_chordDisqualifiedWhenAnyOtherKeyPressed()
func test_rightSideModifiersDoNotTriggerChord()
```

Expected behaviors:
- trigger only after both left modifiers were down and one is released;
- non-modifier key press while candidate active disqualifies;
- right command/right shift are ignored for trigger and may disqualify.

**Step 2: Run test to verify it fails**

Run: `swift test --filter ChordStateMachineTests`
Expected: FAIL because `ChordStateMachine` does not exist.

**Step 3: Write minimal implementation**

Implement deterministic state machine API:

```swift
mutating func handleFlagsChanged(keyCode: CGKeyCode, isDown: Bool, currentFlags: CGEventFlags) -> Bool
mutating func handleKeyDown(keyCode: CGKeyCode) -> Bool
```

Return value indicates "trigger `Ctrl+Space` now".

**Step 4: Run test to verify it passes**

Run: `swift test --filter ChordStateMachineTests`
Expected: PASS.

**Step 5: Commit**

```bash
git add Sources/MacLanguageSwitcher/ChordStateMachine.swift Tests/MacLanguageSwitcherTests/ChordStateMachineTests.swift Sources/MacLanguageSwitcher/main.swift
git commit -m "feat: add left-shift left-command chord state machine"
```

### Task 3: Add event tap service and synthetic Ctrl+Space emitter

**Files:**
- Create: `Sources/MacLanguageSwitcher/HotkeyEventTapService.swift`
- Create: `Sources/MacLanguageSwitcher/ShortcutEmitter.swift`
- Modify: `Sources/MacLanguageSwitcher/main.swift`
- Create: `Tests/MacLanguageSwitcherTests/ShortcutEmitterTests.swift`

**Step 1: Write the failing test**

Create emitter test around event sequence creation abstraction:

```swift
func test_emitterCreatesControlDownSpaceDownSpaceUpControlUpSequence()
```

Use a protocol + fake sink to test sequence without posting real HID events.

**Step 2: Run test to verify it fails**

Run: `swift test --filter ShortcutEmitterTests`
Expected: FAIL because emitter/service code is missing.

**Step 3: Write minimal implementation**

- Build event tap listening to `.flagsChanged` and `.keyDown`.
- Feed events into `ChordStateMachine`.
- On trigger, call `ShortcutEmitter.emitControlSpace()`.
- Never suppress original events (always return pass-through event).

**Step 4: Run test to verify it passes**

Run: `swift test`
Expected: PASS for all tests.

**Step 5: Commit**

```bash
git add Sources/MacLanguageSwitcher/HotkeyEventTapService.swift Sources/MacLanguageSwitcher/ShortcutEmitter.swift Sources/MacLanguageSwitcher/main.swift Tests/MacLanguageSwitcherTests/ShortcutEmitterTests.swift
git commit -m "feat: add event tap service and ctrl-space emitter"
```

### Task 4: Add startup/install tooling and documentation

**Files:**
- Create: `scripts/install-launch-agent.sh`
- Create: `launchd/com.mac-language-switcher.plist`
- Modify: `README.md`

**Step 1: Write the failing test**

Add a lightweight script test file:

Create `Tests/MacLanguageSwitcherTests/LaunchAgentTemplateTests.swift`:

```swift
func test_launchAgentPlistContainsProgramPathPlaceholder()
```

Expected: plist template includes replaceable program path token.

**Step 2: Run test to verify it fails**

Run: `swift test --filter LaunchAgentTemplateTests`
Expected: FAIL until plist/template is created.

**Step 3: Write minimal implementation**

- Add LaunchAgent plist template.
- Add install script to:
  - build release binary,
  - copy binary to `~/Library/Application Support/MacLanguageSwitcher/`,
  - render plist into `~/Library/LaunchAgents/`,
  - load via `launchctl`.
- Document permissions and uninstall steps in README.

**Step 4: Run test to verify it passes**

Run: `swift test`
Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/install-launch-agent.sh launchd/com.mac-language-switcher.plist README.md Tests/MacLanguageSwitcherTests/LaunchAgentTemplateTests.swift
git commit -m "docs: add launch agent installer and usage guide"
```

### Task 5: Final verification and manual QA checklist

**Files:**
- Modify: `README.md` (verification section)

**Step 1: Write the failing test**

No new unit tests; define manual checklist in docs.

**Step 2: Run test to verify it fails**

N/A.

**Step 3: Write minimal implementation**

Add verification commands and manual QA matrix:
- `swift test`
- `swift build -c release`
- verify `Cmd+Shift+T` unchanged
- verify `LShift+LCommand` cycles input source
- verify external Keychron K3v3 behavior

**Step 4: Run test to verify it passes**

Run:
- `swift test`
- `swift build -c release`

Expected: both succeed.

**Step 5: Commit**

```bash
git add README.md
git commit -m "chore: document verification checklist"
```
