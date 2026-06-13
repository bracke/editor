Editor Phase 579 — IDE-grade Outline/Semantic Language Model Pass 154

This pass hardens the compatibility symbol resolver path used by older or
less scope-specific callers.

Changes:
- Updated Editor.Ada_Symbol_Resolver.Name_Matches.
- Depth-bounded Resolve no longer lets an unselected lookup bind to the leaf
  component of a stored selected/dotted declaration name.
- Exact selected names such as Inner.Widget still resolve through the selected
  path.
- Direct unselected declarations such as Widget remain resolvable.
- Added Test_Resolver_Compatibility_Unselected_Lookup_Rejects_Dotted_Leaf.
- Updated outline and semantic-colouring documentation with pass 154 notes.
- Extended tools/release_check.adb guards for the new source/test/doc coverage.

No Python or shell scripts were added. The Ada build/AUnit suite was not run in
this environment because GNAT/gprbuild is unavailable here.
