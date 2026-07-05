Editor pass181 completeness

Scope
- Completes the fixed-width semantic-map overlong identifier safety work.

Changes
- Editor.Syntax_Semantics.Kind_For_Identifier now mirrors Add's no-truncation policy.
- Overlong lookup tokens degrade to ordinary Identifier instead of matching a retained 64-character prefix.
- Added Test_Overlong_Semantic_Lookup_Does_Not_Match_Stored_Prefix.
- Updated docs/outline.md, docs/syntax_colouring.md, docs/commands.md, and tools/release_check.adb.

Validation
- Source inspected and patched in this environment.
- GNAT/gprbuild/AUnit were not available here, so the Ada build and tests were not executed.
- No Python or shell scripts were added to the project.
