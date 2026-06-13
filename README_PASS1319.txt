Pass1319: Generic formal type/family vertical slice legality

This pass adds Editor.Ada_Generic_Formal_Type_Family_Vertical_Slice_Legality.

It is a concrete vertical semantic pass, not another diagnostic/provenance/
remediation wrapper.  It models Ada generic formal type-family legality over
source-shaped formal declarations and actuals, including private, limited
private, tagged private, discrete, signed integer, modular, floating, fixed,
array, access-object, access-subprogram, interface, and derived formal type
families.

The pass checks formal/actual family compatibility, limitedness, taggedness,
definiteness/discriminants, array index and component profiles, access
designated type and subprogram profiles, interface and ancestor requirements,
formal object modes, formal package contracts, formal subprogram profiles,
private/limited/incomplete view barriers, generic body replay availability,
nested instantiation cycles, and source/substitution fingerprint freshness.

Added tests use source-shaped generic formal declarations and actuals rather
than closure-state transitions.
