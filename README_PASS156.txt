Phase 579 pass 156

Focused change:
- Align Ada language-model predicate helpers with retained semantic symbol kinds.

Source changes:
- Editor.Ada_Language_Model.Is_Subprogram now includes Symbol_Separate_Body.
- Editor.Ada_Language_Model.Is_Type_Like now includes Symbol_Generic_Formal_Type.

Tests:
- Added Test_Language_Model_Predicates_Include_Callable_And_Formal_Type.
- The test checks predicate classification and verifies that semantic token mapping remains distinct for separate bodies and generic formal types.

Docs/release guards:
- Updated docs/outline.md and docs/syntax_colouring.md with pass 156 notes.
- Extended tools/release_check.adb guards for the source/test/doc coverage.

Build note:
- GNAT/gprbuild is not available in this execution environment, so the Ada build and AUnit suite were not run here.
