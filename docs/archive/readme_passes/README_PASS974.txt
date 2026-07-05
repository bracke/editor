pass974 — Generic formal subprogram parameter-mode conformance

This pass adds one compiler-grade building block for complete profile conformance in generic-contract matching.

Implemented changes:

* Extended `Generic_Formal_Info` with `Formal_Parameter_Modes`.
* Extended generic formal subprogram profile extraction to retain normalized parameter mode vectors:
  - `in`
  - `out`
  - `in out`
* Preserved the existing normalized subtype-vector comparison and added exact mode-vector comparison for declaration-shaped subprogram actuals.
* Added status:
  - `Generic_Actual_Match_Formal_Subprogram_Mode_Mismatch`
* Added match metadata:
  - `Subprogram_Profile_Mode_Mismatched_Formals`
* Added public deterministic counter:
  - `Subprogram_Profile_Mode_Mismatch_Count_For_Instance`
* Updated overload-aware formal subprogram actual selection so a same-arity/same-subtype actual with different parameter modes is classified as a mode mismatch instead of a generic profile mismatch.
* Added AUnit regression:
  - `Test_Ada_Generic_Formal_Subprogram_Mode_Conformance_Pass974`

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as access-to-subprogram profile conformance, subtype conformance vs type-shape comparison, null-exclusion/profile details, private-view visibility rules, freezing, representation legality, cross-unit semantic closure, and full expression type inference are fully integrated.
