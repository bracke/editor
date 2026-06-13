Editor phase579 IDE-grade Outline/Semantic Language Model pass350

This pass hardens scoped selected-name resolution.

Implemented:
- Updated Editor.Ada_Symbol_Resolver.Resolve_In_Scope so selected-name queries that do not resolve through an exact dotted declaration or a valid selected-prefix child lookup return no match.
- Prevented a scoped query such as `Missing.Widget` from falling through into ordinary lexical leaf lookup and binding an unrelated direct `Widget` declaration in the caller scope.
- Kept supported selected-name resolution intact for exact preserved declarations such as `Shared.Widget` and for valid prefix-owned children such as `Pkg.Widget`.
- Added AUnit regression coverage for scoped selected-name lookup against same-leaf false positives.

Validation hygiene:
- No Python, shell, pyc, or parser-generator tooling was added to the project.
