# Editor Pass759

This pass refines conservative local diagnostics for duplicate Ada representation clauses.

## Changed

* Added a resolved-target helper in the Ada declaration parser so duplicate representation-clause diagnostics are emitted only when both clauses resolve to the same retained target symbol.
* Kept duplicate checks local and syntax/model-backed: textually equal short names in nested declarative regions no longer count as duplicates unless they resolve to the same symbol.
* Preserved existing duplicate detection across unified representation sources such as pragmas, aspects, address clauses, enumeration clauses, record clauses, and attribute-definition clauses.
* Added AUnit regression coverage showing that two `T'Size` clauses for the same outer type are diagnosed while an inner nested `T'Size` clause is not folded into the outer duplicate.
* Updated validation guards and parser coverage documentation.

## Non-goals

This pass does not perform freezing-rule validation beyond existing conservative checks, representation-value legality beyond existing local metadata checks, cross-unit representation analysis, semantic visibility analysis, compiler invocation, LSP integration, rendering-side parsing, or dirty-state mutation.
