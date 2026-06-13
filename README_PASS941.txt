Editor Phase 579 — Pass941
==========================

Pass941 deepens structural grammar recovery for protected entry bodies that omit the `when` barrier before `is`.

Implemented:
- Added `Production_Entry_Body_Missing_Barrier_Recovery_Boundary`.
- Added `Production_Protected_Entry_Body_Missing_Barrier_Recovery_Boundary`.
- Marked ordinary entry-body and protected-body scanner paths when `entry E is` is encountered without a barrier.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Entry_Body_Missing_Barrier_Recovery_Pass941`.
- Updated parser coverage, syntax-colouring notes, validation/release guards, and README.

Scope:
- Improves structural grammar coverage for protected entry-body barrier recovery.
- Does not add compiler-grade tasking legality checking, protected-operation conformance checking, barrier expression legality checking, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.
