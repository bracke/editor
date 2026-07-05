Editor pass981

This pass adds result-subtype conformance for generic formal subprogram actuals.

Changes:
- Added Generic_Actual_Match_Formal_Subprogram_Result_Mismatch.
- Added result-compatible/result-mismatch/result-unknown metadata on Generic_Actual_Match_Info.
- Added Subprogram_Profile_Result_Compatible_Count_For_Instance.
- Added Subprogram_Profile_Result_Mismatch_Count_For_Instance.
- Added Subprogram_Profile_Result_Unknown_Count_For_Instance.
- Extended type-graph-aware profile matching to accept subtype-compatible function results.
- Added Test_Ada_Generic_Formal_Subprogram_Result_Conformance_Pass981.

This is a compiler-grade building block for complete profile conformance. Remaining work includes private-view rules, freezing, representation legality, cross-unit semantic closure, and full expression type inference.
