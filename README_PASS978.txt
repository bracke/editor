Phase 579 pass978 — Generic formal subprogram defaulted-parameter conformance

This pass extends Editor.Ada_Generic_Contracts with a compiler-grade profile-conformance building block for defaulted parameters in generic formal subprogram contracts.

Changes:
- Generic formal subprogram metadata now retains a required/defaulted parameter vector.
- Subprogram actual profile matching now checks whether a formal subprogram contract exposes a defaulted parameter that the selected actual subprogram does not provide.
- Added Generic_Actual_Match_Formal_Subprogram_Default_Mismatch.
- Added Subprogram_Profile_Default_Mismatched_Formals metadata.
- Added Subprogram_Profile_Default_Mismatch_Count_For_Instance.
- Added AUnit regression Test_Ada_Generic_Formal_Subprogram_Default_Conformance_Pass978.

This pass adds one compiler-grade building block for complete profile conformance. Full compiler-grade Ada analysis remains incomplete until private-view rules, freezing/representation legality, cross-unit semantic closure, and full expression type inference are fully integrated.
