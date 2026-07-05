Editor pass999 — separate-body legality closure

This pass adds one compiler-grade building block for cross-unit Ada semantic closure.
Full compiler-grade Ada analysis remains incomplete until the remaining layers such as full expression type inference, deeper generic legality, private-view consumers, freezing completeness, and cross-unit semantic closure are fully integrated.

Summary

- Extended `Editor.Ada_Cross_Unit_Closure` with separate-body legality records.
- Separate bodies are now staged separately from raw separate-parent links.
- Each legality record retains:
  - separate unit name/path/role
  - parent name text from the separate clause
  - resolved parent unit name/path/role
  - candidate count
  - legality status
  - deterministic fingerprint
- Classifies:
  - resolved parent body
  - missing parent body
  - ambiguous parent body
  - overflow
  - parent role mismatch
  - missing parent-name text
- Added counters:
  - `Separate_Body_Legality_Count`
  - `Separate_Body_Resolved_Count`
  - `Separate_Body_Parent_Error_Count`
  - `Separate_Body_Missing_Parent_Count`
  - `Separate_Body_Ambiguous_Parent_Count`
  - `Separate_Body_Target_Name_Missing_Count`
- Added AUnit regression:
  - `Test_Ada_Cross_Unit_Separate_Body_Legality_Pass999`

Files touched

- `src/core/editor-ada_cross_unit_closure.ads`
- `src/core/editor-ada_cross_unit_closure.adb`
- `tests/src/editor-syntax_semantics-tests.adb`
- documentation and release notes
