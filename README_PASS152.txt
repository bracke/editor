Phase 579 IDE-grade Outline/Semantic Language Model — pass 152

This pass hardens scope-aware Ada resolver traversal against impossible parent-scope metadata.

Changes:
- Updated src/core/editor-ada_symbol_resolver.adb.
- Resolve_In_Scope now validates each Current parent scope before attempting to match declarations in that scope.
- Corrupt Parent_Symbol metadata that points from a valid symbol to an impossible parent id now degrades to no match.
- Added Test_Resolver_Invalid_Parent_Scope_Does_Not_Expose_Orphans.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 152 notes.
- Extended tools/release_check.adb guards for the new source/test/doc coverage.

Rationale:
Before this guard, a valid starting symbol could point at a stale/impossible parent id. The next resolver iteration could then match orphaned declarations whose Enclosing_Scope used that same invalid number. That risks false Outline navigation and semantic-colouring bindings from malformed parser/test data. The resolver now fails closed instead.

Validation:
- No Python or shell scripts were added.
- Ada build/AUnit execution was not run in this environment because GNAT/gprbuild is unavailable here.
