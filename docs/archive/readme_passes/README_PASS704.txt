# Editor Pass 704

Pass 704 deepens structural grammar coverage for Ada renaming declarations and renamed targets.

## Implemented

- Added token-cursor productions for renamed object, package, subprogram, and generic-unit targets.
- Added structural markers for selected renamed targets and operator-symbol renamed targets.
- Added a bounded renaming recovery marker for declarations that reach `renames ;` without a target.
- Improved parser retention for:
  - object renamings with indexed/selected targets.
  - package renamings with selected package names.
  - procedure/function renamings with selected targets.
  - operator-function renamings such as `function "*" ... renames Math."*";`.
  - generic package and generic subprogram renamings.
  - malformed renaming declarations that must continue into following declarations.
- Added AUnit regression coverage in `Test_Language_Model_Token_Cursor_Renaming_Target_Depth_Grammar_Completeness`.
- Updated the language validation guard, README, Outline notes, syntax-colouring notes, and release checklist.

## Scope

This is structural parser coverage only. It does not implement compiler-grade legality checking for renamed entity resolution, visibility, overload resolution, profile conformance, generic renaming legality, operator-symbol legality, subtype conformance, or elaboration rules.
