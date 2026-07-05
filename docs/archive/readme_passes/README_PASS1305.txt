Pass1305 - Ada 2022 expression type-resolution vertical slice

This pass adds Editor.Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality.

The pass is intentionally a concrete vertical semantic slice, not another diagnostic/provenance/recheck wrapper. It consumes source-shaped Ada 2022 expression rows and validates real type-resolution prerequisites for constructs whose parser/AST coverage was modelled in Pass1304.

Covered constructs:
- quantified expressions
- reduction expressions
- delta aggregates
- container aggregates
- declare expressions
- target-name/update-expression contexts
- generalized indexing
- parallel loops

Covered legality checks:
- quantified predicates must resolve to Boolean
- reduction combiner profiles must match accumulator/element types
- reduction seed values must match accumulator type, including universal integer compatibility
- delta aggregate bases must be composite and component updates must be compatible
- container aggregate elements must match the container element model
- declare expression result types must match the expected type and declarations must be elaborable
- target-name @ must appear only in update contexts
- generalized indexing profiles and result types must match the expected type
- parallel loops require shared-state safety evidence
- expected-result compatibility, universal numeric compatibility, runtime accessibility checks, source fingerprint freshness, and AST fingerprint freshness are tracked

Added tests:
- Test_Ada_Ada2022_Expression_Type_Resolution_Vertical_Slice_Legality_Pass1305

This pass adds one compiler-grade building block for Ada 2022 expression typing over concrete parser/AST-covered constructs. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
