Pass1051 - Ada overload ambiguity diagnostics

Implemented package:
- Editor.Ada_Overload_Ambiguity_Diagnostics

Scope:
- Consumes Editor.Ada_Expression_Types.
- Classifies existing call, operator, and universal-numeric inference metadata into deterministic overload ambiguity/candidate-rejection diagnostics.
- Preserves expression identity, syntax node, source span, severity, diagnostic kind, candidate counts, selected counts, compatible/mismatch/unknown counters, explanatory message/detail text, source fingerprint, and diagnostic fingerprint.
- Adds lookup by syntax node and deterministic counters by cause family and reason class.

Counters:
- Diagnostic_Count
- Error_Count
- Warning_Count
- Info_Count
- Call_Cause_Count
- Operator_Cause_Count
- Universal_Numeric_Cause_Count
- Candidate_Rejection_Count
- Ambiguous_Cause_Count
- Mismatch_Cause_Count
- Unknown_Cause_Count
- Count_Kind
- Fingerprint

Regression:
- Test_Ada_Overload_Ambiguity_Diagnostics_Pass1051

Invariant:
- No rendering-side parsing.
- No file saves/reloads during analysis.
- No dirty-state mutation.
- No command/keybinding/workspace/render mutation.
- No compiler invocation, LSP, parser generator, Python, or shell integration in the project code.
