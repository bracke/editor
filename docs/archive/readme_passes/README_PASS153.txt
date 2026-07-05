Editor — IDE-grade Outline/Semantic Language Model Pass 153

This pass hardens scoped resolver matching for unselected identifiers.

Changes:
- Added scoped resolver matching that rejects leaf-only fallback for stored selected/dotted declaration names.
- `Resolve_In_Scope` no longer lets an unselected query such as `Widget` bind to a declaration stored as `Inner.Widget` in the same lexical scope.
- Exact selected-name lookup for `Inner.Widget` remains supported when visible.
- Added `Test_Resolver_Unselected_Lookup_Rejects_Dotted_Leaf`.
- Updated Outline and semantic-colouring documentation.
- Extended release_check guards.

Validation:
- No Python or shell scripts were added.
- GNAT/gprbuild is not available in this execution environment, so the Ada build and AUnit suite were not run here.
