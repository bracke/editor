Phase 579 pass 168

Focus: selected-name resolver ownership hardening.

Changes:
- Hardened Editor.Ada_Symbol_Resolver.Resolve_In_Scope selected-prefix lookup.
- After a prefix such as A resolves, A.Widget now requires both Enclosing_Scope and Parent_Symbol to point at A.
- Malformed rows whose lexical scope and parent symbol disagree no longer become selected-name Outline/navigation or semantic-colouring matches.
- Added Test_Resolver_Selected_Name_Requires_Matching_Parent.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 168 notes.
- Extended tools/release_check.adb guards for the new source/test/doc coverage.

Validation note:
- GNAT/gprbuild/AUnit were not available in this execution environment, so the Ada suite was not run here.
- No Python or shell scripts were added to the project.
