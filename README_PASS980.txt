Editor Phase 579 pass980

Compiler-grade building block: generic formal subprogram parameter-name profile conformance.

Changes:
- Extended Editor.Ada_Generic_Contracts with normalized formal subprogram parameter-name vectors.
- Generic formal subprogram actual matching now treats parameter-name mismatches as a distinct profile-conformance failure.
- Added Generic_Actual_Match_Formal_Subprogram_Name_Mismatch.
- Added Subprogram_Profile_Name_Mismatched_Formals metadata.
- Added Subprogram_Profile_Name_Mismatch_Count_For_Instance.
- Added AUnit regression Test_Ada_Generic_Formal_Subprogram_Name_Conformance_Pass980.

Full compiler-grade Ada analysis remains incomplete until remaining layers such as private-view visibility rules, freezing, representation legality, cross-unit semantic closure, full expression type inference, and deeper generic body/instance legality are fully integrated.
