# Input Source HUD Desync Mitigation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Eliminate confusing input-source HUD mismatches by making API-based switching transactional, serialized, and observable.

**Architecture:** Keep `Left Shift + Left Command` chord detection unchanged, but turn input-source change into a verified switch transaction. A switch request computes a target source, performs `TISSelectInputSource`, then verifies convergence to the target source via `currentSourceID`/notification before accepting another switch.

**Tech Stack:** Swift 6, Carbon Text Input Source APIs (`TIS*`), Foundation notifications/timers, XCTest.

---

### Task 1: Add switch transaction result model and post-select verification

**Files:**
- Modify: `Sources/MacLanguageSwitcher/InputSourceSwitcher.swift`
- Modify: `Tests/MacLanguageSwitcherTests/InputSourceSwitcherTests.swift`

**Step 1: Write the failing test**

Add tests for transactional behavior:

```swift
func test_cycle_reportsTargetAndConfirmsWhenCurrentBecomesTarget()
func test_cycle_retriesOnceWhenCurrentDidNotMoveToTarget()
func test_cycle_failsWhenSelectSucceedsButCurrentNeverBecomesTarget()
```

Model the provider with programmable `currentSourceID` progression so tests can simulate delayed or missing convergence.

**Step 2: Run test to verify it fails**

Run: `swift test --filter InputSourceSwitcherTests`
Expected: FAIL because switcher currently returns only `Bool` and has no convergence check.

**Step 3: Write minimal implementation**

Implement a transactional API in `InputSourceSwitcher`, e.g.:

```swift
struct SwitchResult {
    let triggered: Bool
    let fromID: String?
    let targetID: String?
    let converged: Bool
    let attempts: Int
}
```

Behavior:
- Determine `targetID` from enabled list + current ID.
- Attempt select.
- Verify `currentSourceID == targetID` (immediate check + bounded retry window).
- Return structured result (not just success bool).

**Step 4: Run test to verify it passes**

Run: `swift test --filter InputSourceSwitcherTests`
Expected: PASS.

**Step 5: Commit**

```bash
git add Sources/MacLanguageSwitcher/InputSourceSwitcher.swift Tests/MacLanguageSwitcherTests/InputSourceSwitcherTests.swift
git commit -m "fix: make input source switch transactional and verified"
```

### Task 2: Serialize switch requests and block overlap in event service

**Files:**
- Modify: `Sources/MacLanguageSwitcher/HotkeyEventTapService.swift`
- Modify: `Tests/MacLanguageSwitcherTests/ChordStateMachineTests.swift`
- Create: `Tests/MacLanguageSwitcherTests/HotkeyEventTapServiceTests.swift`

**Step 1: Write the failing test**

Add service-level tests (with test double for switcher) asserting:

```swift
func test_ignoresTriggerWhileSwitchInFlight()
func test_allowsNextTriggerAfterSwitchCompletes()
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter HotkeyEventTapServiceTests`
Expected: FAIL because service currently allows immediate back-to-back switch invocation.

**Step 3: Write minimal implementation**

In `HotkeyEventTapService`:
- Add `isSwitchInFlight` gate.
- Set gate before scheduling switch.
- Clear gate only after switch transaction reports completion.
- Emit debug logs with `fromID`, `targetID`, `converged`, and attempt count.

**Step 4: Run test to verify it passes**

Run: `swift test --filter HotkeyEventTapServiceTests`
Expected: PASS.

**Step 5: Commit**

```bash
git add Sources/MacLanguageSwitcher/HotkeyEventTapService.swift Tests/MacLanguageSwitcherTests/HotkeyEventTapServiceTests.swift Tests/MacLanguageSwitcherTests/ChordStateMachineTests.swift
git commit -m "fix: serialize input source switches and prevent overlap"
```

### Task 3: Hook notification-based observability for source-change completion

**Files:**
- Modify: `Sources/MacLanguageSwitcher/InputSourceSwitcher.swift`
- Create: `Sources/MacLanguageSwitcher/InputSourceNotifications.swift`
- Modify: `Tests/MacLanguageSwitcherTests/InputSourceSwitcherTests.swift`

**Step 1: Write the failing test**

Add tests for notification-assisted completion path:

```swift
func test_cycle_waitsForSelectedKeyboardInputSourceChangedNotification()
func test_cycle_timesOutWhenNoNotificationAndNoConvergence()
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter InputSourceSwitcherTests`
Expected: FAIL because no notification abstraction exists.

**Step 3: Write minimal implementation**

- Wrap `kTISNotifySelectedKeyboardInputSourceChanged` in a tiny observer abstraction.
- During switch transaction, use condition-based waiting with deadline.
- Prefer convergence by actual `currentSourceID`; notification is a synchronization signal, not truth source.

**Step 4: Run test to verify it passes**

Run: `swift test --filter InputSourceSwitcherTests`
Expected: PASS.

**Step 5: Commit**

```bash
git add Sources/MacLanguageSwitcher/InputSourceSwitcher.swift Sources/MacLanguageSwitcher/InputSourceNotifications.swift Tests/MacLanguageSwitcherTests/InputSourceSwitcherTests.swift
git commit -m "feat: add source-change notification synchronization"
```

### Task 4: Update docs and debug playbook for HUD mismatch diagnosis

**Files:**
- Modify: `README.md`

**Step 1: Write the failing test**

No unit test. Add doc acceptance criteria:
- clearly states that macOS HUD is advisory
- logs expose authoritative before/target/after source IDs
- includes one troubleshooting command sequence

**Step 2: Run test to verify it fails**

N/A.

**Step 3: Write minimal implementation**

Update README with:
- explanation of verified switch transaction,
- new debug fields in logs,
- troubleshooting sequence for “HUD icon differs from actual typing source”.

**Step 4: Run test to verify it passes**

Run: `swift test`
Expected: PASS.

**Step 5: Commit**

```bash
git add README.md
git commit -m "docs: document transactional switch behavior and HUD troubleshooting"
```

### Task 5: End-to-end verification on real keyboard paths

**Files:**
- Modify: `README.md` (verification section if needed)

**Step 1: Write the failing test**

No new automated test; define manual QA matrix.

**Step 2: Run test to verify it fails**

N/A.

**Step 3: Write minimal implementation**

Manual validation script:
- Built-in keyboard: 200 rapid toggles, verify no missed/extra switch.
- Keychron K3v3 wired + Bluetooth: same run.
- Window/app switching paths (`Cmd+Tab`, trackpad swipe, `Ctrl+Arrow`) during toggling.
- Confirm logs always show `converged=true` when a switch is triggered.

**Step 4: Run test to verify it passes**

Run:
- `swift test`
- `swift build -c release`

Expected: both succeed.

**Step 5: Commit**

```bash
git add README.md
git commit -m "chore: add validation matrix for input source consistency"
```
