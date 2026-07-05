Editor pass979

This pass adds one compiler-grade building block for generic formal subprogram profile conformance: class-wide/controlling-profile compatibility.

Changes:
- Extended Editor.Ada_Generic_Contracts with class-wide profile mismatch metadata.
- Added Generic_Actual_Match_Formal_Subprogram_Class_Wide_Mismatch.
- Added Subprogram_Profile_Class_Wide_Mismatched_Formals metadata.
- Added Subprogram_Profile_Class_Wide_Mismatch_Count_For_Instance.
- Generic formal subprogram actual selection now distinguishes Root versus Root'Class profile mismatches from broad profile mismatches.
- Added AUnit regression Test_Ada_Generic_Formal_Subprogram_Class_Wide_Conformance_Pass979.

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as private-view visibility rules, freezing, representation legality, cross-unit semantic closure, full expression type inference, and deeper generic body/instance legality are fully integrated.
