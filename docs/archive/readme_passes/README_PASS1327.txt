Pass1327 implements Editor.Ada_Assignment_Conversion_Vertical_Slice_Legality.

This pass continues the post-1297 vertical-slice strategy and adds a concrete
assignment/conversion legality engine rather than a diagnostic/provenance wrapper.

Implemented legality coverage:

* Assignment statements with variable-view target checks.
* Assignment type compatibility across exact/base/root/numeric families.
* Rejection of constant-view and limited-view assignment targets.
* Type conversions and qualified expressions.
* View conversions, including limited-view rejection.
* Class-wide conversions with class-wide evidence gates.
* Numeric conversions with numeric source/target evidence and range blockers.
* Access conversions with access-kind/profile conformance gates.
* Null-exclusion violations.
* Static accessibility blockers and runtime accessibility checks.
* Static range blockers and runtime range checks.
* Predicate blockers and runtime predicate checks.
* Private, limited, incomplete, and generic-formal view barriers.
* Controlled/finalized assignment/conversion blockers.
* Source, AST, type, and substitution fingerprint freshness checks.
* Deterministic result fingerprints, legal/error counts, and blocker preservation.

Added AUnit coverage:

* Legal assignment requiring a runtime range check.
* Constant target plus type mismatch preservation.
* Explicit type conversions and qualified expressions.
* View, class-wide, numeric, and access-conversion blockers.
* Null-exclusion, accessibility, range, and predicate blockers.
* Private-view barrier and stale AST fingerprint rejection.

Registered test:

* Test_Ada_Assignment_Conversion_Vertical_Slice_Legality_Pass1327
