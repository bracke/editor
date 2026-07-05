Editor IDE-grade outline/semantic language model pass 166

This pass hardens scoped Ada symbol resolution against malformed value-like
starting scopes.

Changes:
- Editor.Ada_Symbol_Resolver.Resolve_In_Scope now accepts a non-root
  From_Scope only when that id is a declaration-owning symbol retained by the
  current Analysis_Result.
- Parent-chain walking also stops if corrupt metadata reaches a value-like
  symbol, preventing object/component/literal rows from becoming lexical scopes.
- Added Test_Resolver_Non_Owner_Start_Scope_Degrades.
- Updated docs/outline.md and docs/syntax_colouring.md.
- Extended tools/release_check.adb guards for the new source/test/doc coverage.

No Python or shell scripts were added to the project.
