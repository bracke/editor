Editor Phase 579 pass 369 — ambiguity-aware IDE navigation candidates

This pass adds an ambiguity-aware navigation candidate layer on top of the
existing conservative unique target APIs.

Implemented:
- Editor.Ada_Project_Index.Navigation_Target_Status
- Editor.Ada_Project_Index.Navigation_Candidate_Result
- Resolve_Navigation_Candidates
- Resolve_Related_Unit_Candidates
- Resolve_Unit_Family_Targets

The new APIs expose unavailable/unique/ambiguous/overflow states and retain the
validated candidate target list for UI/chooser surfaces. Existing goto execution
can keep requiring unique targets, while future IDE UI can present all validated
ambiguous candidates without doing unsafe leaf-name scans or choosing the first
match.

Added regression coverage:
- Test_Project_Index_Navigation_Candidates_Report_Ambiguity

No Python, shell scripts, parser generators, rendering-side parsing, external
compiler integration, or LSP integration were added.
