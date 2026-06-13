Phase 579 pass 148

Focus:
- Harden the Ada language-model overload enumeration API against invalid or stale scope ids.

Source changes:
- Added a local Valid_Scope helper in Editor.Ada_Language_Model.
- Updated Overload_Count and Overload_At so they only enumerate overload sets for Root_Scope or a symbol scope owned by the current Analysis_Result.
- Invalid/stale scope ids now degrade to zero overloads or No_Symbol instead of exposing malformed rows whose Enclosing_Scope happens to match the impossible scope value.

Tests/docs/guards:
- Added Test_Language_Model_Invalid_Scope_Overload_Lookup_Degrades.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 148 notes.
- Extended tools/release_check.adb guards for the source/test/doc changes.

Validation note:
- GNAT/gprbuild is not available in this environment, so the Ada build and AUnit suite were not run here.
- No Python or shell scripts were added to the project.
