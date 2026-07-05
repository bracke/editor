Editor IDE-grade Outline/Semantic Language Model — Pass 201

Purpose
-------
Pass 201 closes a declaration-navigation availability gap.  Earlier passes
hardened indexed body/spec navigation at execution time, but the ordinary
selected Outline declaration path could still be advertised as available when
the selected row was only selectable, not a currently live activation target.

Changes
-------
- Added Has_Selected_Outline_Activation_Target in Editor.Executor.
- Command_Open_Selected_Outline_Item availability now requires the selected
  Outline row to validate as an activation target and to point at a live,
  in-range buffer position.
- Command_Goto_Declaration availability now uses the same target-aware check.
- Execution remains unchanged and continues to perform the final target handoff
  validation before moving focus/caret.
- Added AUnit regression marker/test:
  Test_Declaration_Navigation_Availability_Rejects_Stale_Target
- Extended tools/language_validation_check.adb to require that test.
- Updated docs/commands.md, docs/outline.md, docs/release/RELEASE_CHECKLIST.md,
  and README.md.

Validation
----------
Static validation performed in this environment:
- no legacy Outline Ada fallback scanner markers were reintroduced;
- no Python or shell scripts were added;
- pass 201 implementation/test/validation markers are present;
- archive integrity was checked after packaging.

GNAT/AUnit validation was not run here because the Ada toolchain is unavailable.
Run the strict validation gate on an Ada machine:

  EDITOR_REQUIRE_LANGUAGE_VALIDATION=1 tools/bin/language_validation_check
