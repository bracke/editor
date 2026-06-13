Pass1045 - Ada diagnostic navigation model

This pass adds one compiler-grade building block for IDE-facing semantic diagnostics navigation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Implemented:

- Added Editor.Ada_Diagnostic_Navigation.
- Consumes Editor.Ada_Semantic_Diagnostic_Index only; it performs no parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering work.
- Provides deterministic first and last diagnostic lookup.
- Provides deterministic next and previous diagnostic navigation from source line/column positions.
- Provides severity-filtered first, last, next, and previous navigation for errors, warnings, and infos through the existing semantic diagnostic feed severity enum.
- Preserves stable diagnostic identity from the index/feed, source span, severity, source family, token kind, syntax node, message payload, feed index, index id, and fingerprint.
- Rejected/stale diagnostic indexes expose no navigation targets while preserving rejected-target counts.
- Adds deterministic counters:
  - Navigation_Target_Count
  - Error_Target_Count
  - Warning_Target_Count
  - Info_Target_Count
  - Rejected_Target_Count
  - Fingerprint
- Adds AUnit regression coverage through Test_Ada_Diagnostic_Navigation_Pass1045.

Updated documentation:

- README.md
- docs/ada_parser_coverage_matrix.md
- docs/syntax_colouring.md
- docs/syntax_colouring_notes.md
- docs/release_checklist.md
- docs/release/RELEASE_CHECKLIST.md
- docs/strict_runtime_validation.md
- docs/release/STRICT_RUNTIME_VALIDATION.md

Package:

- editor_phase579_ide_grade_outline_semantic_language_model_pass1045.zip
