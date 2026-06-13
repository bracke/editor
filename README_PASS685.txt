Pass 685 - Formal package declaration actual association grammar depth

This pass improves structural grammar coverage for Ada generic formal package
declarations.  The token cursor now retains the formal package defining name and
formal-package-specific actual associations instead of relying only on ordinary
generic-instantiation actual productions for non-box actual parts.

Implemented changes:

- Added `Production_Formal_Package_Defining_Name` for the defining identifier in
  `with package P is new G ...` declarations.
- Added `Production_Formal_Package_Actual_Association` for each association in a
  formal package actual part such as `(Key_Type => Key, others => <>)`.
- Added `Production_Formal_Package_Actual_Formal_Selector` for named formal
  package actual selectors, including reserved-word selectors such as `others`
  and operator-symbol selectors such as `"<"`.
- Added `Production_Formal_Package_Actual_Association_Box` for association-level
  `=> <>` boxes, while preserving the existing whole-actual-part `(<>)`
  production separately.
- Preserved the shared generic-actual productions for compatibility with
  existing instantiation-oriented callers, while making the enclosing formal
  package declaration distinguishable for Outline and semantic-colouring use.
- Added AUnit coverage for selected generic package names, named actual
  selectors, operator selectors, whole-part boxes, association-level boxes, and
  bounded recovery into the following generic formal declaration after a
  malformed formal package actual list.

This is structural parser coverage for editor language intelligence.  It is not
compiler-grade legality checking for generic formal package contracts, formal
package matching, generic actual type conformance, visibility, staticness, box
legality, or generic instantiation elaboration rules.
