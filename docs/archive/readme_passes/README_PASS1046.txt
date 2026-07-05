Pass1046 implements the Ada diagnostic panel projection model.

Added:
- Editor.Ada_Diagnostic_Panel_Projection
- deterministic panel rows over Editor.Ada_Semantic_Diagnostic_Index
- severity grouping metadata for error, warning, and info rows
- semantic source-family counters and group counts
- optional file and unit group metadata for IDE diagnostic panels
- selected-row state and nearest-row selection from source line/column
- stale/rejected index handling that withholds all rows while preserving rejected totals
- deterministic row/model fingerprints
- Test_Ada_Diagnostic_Panel_Projection_Pass1046

This pass adds one compiler-grade building block for IDE-facing diagnostic presentation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
