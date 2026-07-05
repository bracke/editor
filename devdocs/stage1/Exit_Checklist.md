# Exit Checklist

is complete when the editor core is stable, deterministic, and fully specified.

---

## Runtime / Integration

- [ ] Window opens successfully
- [ ] Event loop runs without crashing
- [ ] Ada core is linked and callable from runtime
- [ ] Editor instance can be created and rebuilt
- [ ] Replay determinism passes

---

## Core Editing Behavior

- [ ] Single caret works correctly
- [ ] Caret movement left/right is correct
- [ ] Caret range is valid: `0 .. Length + 1`
- [ ] Selection starts correctly on first shift-move
- [ ] Selection anchor remains fixed
- [ ] Selection end follows caret
- [ ] Reverse selection works
- [ ] Selection collapses correctly on non-shift movement
- [ ] Insert works without selection
- [ ] Delete works without selection
- [ ] Insert replaces active selection
- [ ] Delete removes active selection

---

## Undo / Redo

- [ ] Undo restores buffer correctly
- [ ] Undo restores caret correctly
- [ ] Undo restores selection correctly
- [ ] Redo restores buffer correctly
- [ ] Redo restores caret correctly
- [ ] Redo restores selection correctly
- [ ] Undo/Redo replay is deterministic

---

## Buffer / Backend Semantics

- [ ] Insert semantics are documented
- [ ] Delete semantics are documented
- [ ] Delete_Range semantics are documented
- [ ] Caret-space to buffer-space mapping is documented
- [ ] No known off-by-one issues remain
- [ ] No backend index crashes remain

---

## State Invariants

- [ ] Exactly one caret exists in Stage 1
- [ ] Caret is always within `0 .. Length + 1`
- [ ] Selection positions are always within `0 .. Length + 1`
- [ ] Inactive selection is collapsed at caret
- [ ] Selection state is stored unnormalized
- [ ] Span is only normalized at use sites (`min/max`)

---

## Tests

- [X] Executor tests pass
- [X] Selection tests pass
- [X] History tests pass
- [X] Instance tests pass
- [X] State tests pass
- [X] No expected failures remain
- [X] No flaky tests remain

---

## Code Quality / Freeze

- [x] `DESIGN.md` reflects actual behavior
- [x] Temporary debug code removed
- [x] Stale comments removed
- [x] Naming is consistent
- [x] No known semantic drift remains between tests and implementation
- [x] behavior is considered frozen

---

## Done Definition

is done when:

- the full test suite is green
- replay is deterministic
- no crashes occur in core editing paths
- the indexing model is stable and documented
- invariants are written down and enforced
- no hidden executor/backend mismatches remain