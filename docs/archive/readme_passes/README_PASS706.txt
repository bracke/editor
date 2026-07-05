# Editor pass706 semantic-colouring precision

Pass706 refines parser-owned Ada semantic-colouring classification for executable binding metadata.

## Changed

* Updated `Editor.Syntax_Semantics.Build_Map_From_Analysis` so unresolved executable bindings are classified by conservative syntax role instead of using a broad value-like fallback.
* Callable-shaped bindings now colour as `Subprogram_Identifier` when the parser retained a safe callable role but resolver target information is unavailable:
  * call targets
  * select entry calls
  * requeue targets
  * accept entries
* Type-shaped bindings now colour as `Type_Identifier`:
  * qualified-expression targets
  * type-conversion targets
  * allocator targets
* Local definition/value roles continue to colour as `Parameter_Identifier`, including:
  * accept parameters
  * entry-family indexes
  * labels
  * guards, barriers, case/conditional branches, raise targets, and local object-like bindings
* Ambiguous reference-only forms now degrade to ordinary identifiers when unresolved:
  * selected components
  * attribute prefixes
  * index/slice/range/source/dereference/reference-only expression roles
* Added AUnit coverage in `Test_Analysis_Binding_Semantic_Colouring_Precision`.
* Updated validation guards and semantic-colouring documentation.

## Scope

This improves semantic-colouring precision for parser-owned Ada language-model metadata. It is not compiler-grade name resolution, overload resolution, visibility checking, subtype resolution, attribute legality checking, or project-wide semantic analysis.
