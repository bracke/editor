Phase 579 IDE-grade outline/semantic language-model pass 144

This pass hardens selected-name resolution in Editor.Ada_Symbol_Resolver.

Change summary:
- Resolve_In_Scope keeps exact selected-name lookup unchanged.
- After resolving a selected prefix scope, the resolver now requires the final component to match a direct symbol name in that selected scope.
- This prevents a dotted child such as Inner.Widget, stored under Pkg, from satisfying Pkg.Widget by leaf-only fallback.
- Added Test_Resolver_Selected_Name_Rejects_Dotted_Child_Leaf.
- Updated outline/semantic-colouring docs and release_check guards.

No Python or shell scripts were added to the project.
