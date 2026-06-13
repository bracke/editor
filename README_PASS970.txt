# Editor Phase 579 pass970

Pass970 extends `Editor.Ada_Generic_Contracts` with deterministic formal package contract conformance metadata for generic instantiations.

Implemented changes:

* Generic formal package records retain the target generic named by `with package Formal is new Target (...)`, a normalized target key, and whether the formal package uses box actuals.
* Generic actual matching resolves package actual designators through direct visibility and verifies that declaration-shaped actuals are package instantiations.
* Inline package actuals such as `Helper => new Generic_Helper (Integer)` are recognized and matched against the expected formal package target generic.
* Wrong-generic package instances, non-instance package declarations, unresolved package actuals, ambiguous package actuals, malformed package actuals, and unknown formal package contracts are separated from ordinary formal-kind mismatches.
* Deterministic counters were added for formal package compatible, mismatched, and unknown contract checks.
* AUnit regression coverage was added in `Test_Ada_Generic_Formal_Package_Contract_Conformance_Pass970`.

Scope:

This pass adds one compiler-grade generic-contract building block for formal package conformance. Full compiler-grade Ada analysis remains incomplete until remaining layers such as overload-aware actual selection, generic body contract visibility, private-view rules, default-expression legality, freezing/representation legality, representation-clause legality, and cross-unit semantic closure are fully integrated.
