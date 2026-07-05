IDE-grade outline/semantic language-model pass 139

This pass hardens bounded semantic-map insertion for long Ada identifiers.

Changes:
- Editor.Syntax_Semantics.Add now refuses to store names longer than the fixed semantic key width.
- Overlong semantic names mark Symbol_Cap_Reached/Symbol_Overflow and degrade to ordinary identifiers.
- This avoids false positives where two different long names share the same first 64 characters.
- Added AUnit coverage: Test_Overlong_Semantic_Names_Degrade_To_Identifiers.
- Updated docs/outline.md and docs/syntax_colouring.md.
- Extended tools/release_check.adb guards.

Build note:
- GNAT/gprbuild was not available in this execution environment, so the Ada build and AUnit suite were not run here.
- No Python or shell scripts were added to the project.
