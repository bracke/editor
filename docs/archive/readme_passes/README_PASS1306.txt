Pass1306 adds Editor.Ada_Subtype_Range_Predicate_Vertical_Slice_Legality.

This is a vertical semantic slice, not another diagnostic/provenance/closure loop. It adds concrete subtype, range, scalar constraint, and predicate legality that downstream expression/type resolution can consume.

Implemented coverage:
- scalar and discrete range constraints
- modular subtype ranges and modulus bounds
- floating digits constraints
- fixed-point delta constraints
- array index discrete subtype checks
- predicate Boolean result checking
- Static_Predicate staticness and range validation
- Dynamic_Predicate runtime-check acceptance
- expected/base type compatibility, including universal numeric contexts
- stale source/AST fingerprint rejection
- multiple-blocker and indeterminate classification

AUnit coverage:
- legal concrete subtype constraints
- invalid range/modular/digits/delta/index rows
- static and dynamic predicate rows
- AST/fingerprint/multiple/indeterminate blocker preservation
