Editor IDE-grade outline/semantic language-model pass 161

This pass hardens project-wide symbol lookup so unselected project-index queries
respect the same selected-name boundary as the scoped resolver.

Changes:
- Editor.Ada_Project_Index.Symbol_Matches now rejects leaf-only matches against
  retained selected/dotted declaration names for unselected queries.
- Exact selected-name lookup remains supported.
- Direct unselected declarations remain resolvable.
- Added Test_Project_Index_Unselected_Lookup_Rejects_Dotted_Leaf.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 161 notes.
- Extended tools/release_check.adb guards.

Build/test note:
- The Ada build and AUnit suite were not run in this environment because
  GNAT/gprbuild is unavailable here.
