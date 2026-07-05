Pass1315 implements Editor.Ada_Membership_Case_Choice_Vertical_Slice_Legality.

This is a vertical Ada semantic slice, not another diagnostic/provenance/recheck wrapper.

The pass adds concrete membership and case-choice legality for Ada constructs that depend on precise static numeric/subtype evidence:

- membership tests and not-in tests
- case statements and case expressions
- variant choices
- aggregate/index/discriminant choices
- discrete subject checks
- choice type compatibility
- static choice requirements
- range bound order and base-range validation
- case choice presence and completeness
- overlapping choices
- others placement and duplicate others choices
- variant governor compatibility
- aggregate choice compatibility
- runtime membership checks where legal
- stale source/AST/type/static fingerprint rejection

The AUnit tests use source-shaped membership, case, variant, aggregate, and stale-evidence scenarios instead of synthetic closure-state rows.
