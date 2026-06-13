Editor Phase 579 pass977

This pass adds one compiler-grade building block for generic formal subprogram profile conformance: calling-convention conformance.

Implemented:
- Generic formal subprogram records now retain normalized convention metadata.
- Actual subprogram profile matching now compares actual calling convention against the formal subprogram convention.
- Default convention is staged conservatively as Ada when no explicit Convention aspect is present.
- Convention mismatches are classified separately from broad profile mismatches.
- Added Generic_Actual_Match_Formal_Subprogram_Convention_Mismatch.
- Added deterministic metadata field Subprogram_Profile_Convention_Mismatched_Formals.
- Added public API Subprogram_Profile_Convention_Mismatch_Count_For_Instance.
- Added AUnit regression Test_Ada_Generic_Formal_Subprogram_Convention_Conformance_Pass977.

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as private-view visibility rules, freezing and representation legality, cross-unit semantic closure, and full expression type inference are fully integrated.
