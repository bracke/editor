Editor pass976

This pass adds one compiler-grade building block for generic formal subprogram profile conformance: null-exclusion and anonymous access-to-subprogram profile matching.

Implemented:
- Generic actual matching separates formal subprogram null-exclusion mismatches from broad profile mismatches.
- Generic actual matching separates anonymous access-to-subprogram profile mismatches from broad profile mismatches.
- Added deterministic metadata fields and counters for both mismatch classes.
- Added public APIs Subprogram_Profile_Null_Exclusion_Mismatch_Count_For_Instance and Subprogram_Profile_Access_Profile_Mismatch_Count_For_Instance.
- Added AUnit regression Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance_Pass976.

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as private-view visibility rules, freezing and representation legality, cross-unit semantic closure, and full expression type inference are fully integrated.
