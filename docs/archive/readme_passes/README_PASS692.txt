# Editor Pass 692

This pass deepens structural Ada expression grammar coverage in the internal token-cursor parser while preserving the invariants: no rendering-side parsing, no dirty-state mutation, no compiler/LSP dependency, and deterministic snapshot-owned analysis.

## Implemented grammar refinements

- Added explicit branch-expression retention for conditional expressions:
  - `Production_If_Expression_Branch_Expression`
- Added explicit case-expression alternative structure:
  - `Production_Case_Expression_Choice_List`
  - `Production_Case_Expression_Arrow`
- Added explicit quantified-expression arrow retention:
  - `Production_Quantified_Arrow`
- Added distinct reduction-family markers:
  - `Production_Parallel_Reduction_Expression`
  - `Production_Map_Reduction_Expression`
- Preserved existing expression markers for conditional, case, quantified, qualified, allocator, raise, and reduction expressions.

## Regression coverage

AUnit coverage now guards nested expression-family recovery across:

- conditional expressions with nested case expressions in branches;
- quantified expressions with iterator filters and predicate arrows;
- qualified allocator expressions inside conditional branches;
- `Parallel_Reduce` and `Map_Reduce` attribute-expression classification;
- recovery into following declarations after nested expression parsing.

## Scope

This improves structural grammar coverage for Ada expression families. It is not compiler-grade legality checking for expression typing, overload resolution, staticness, accessibility, allocator legality, quantified-expression legality, reduction reducer/profile conformance, or parallel-reduction execution semantics.
