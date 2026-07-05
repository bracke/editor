IDE-grade outline/semantic language model pass 151

This pass hardens exact selected-name resolution in Editor.Ada_Symbol_Resolver.Resolve_In_Scope.

Changes:
- Added a bounded Scope_Is_Visible helper for selected-name fast-path lookup.
- Exact dotted declarations are now accepted only when they are root-owned units or visible from the caller's lexical scope chain.
- Prevents preserved dotted declarations from unrelated nested scopes from leaking into Outline/navigation or semantic colouring selected-name targets.
- Added Test_Resolver_Exact_Selected_Name_Respects_Scope.
- Updated docs/outline.md, docs/syntax_colouring.md, and tools/release_check.adb guards.

No Python or shell scripts were added to the project.
