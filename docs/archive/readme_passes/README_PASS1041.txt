Pass1041 - semantic-colouring diagnostics projection

This pass adds one compiler-grade IDE integration building block for Ada semantic diagnostics.

Implemented:
- Added Editor.Ada_Semantic_Colour_Projection.
- Projects expression, generic-contract, cross-unit, and representation/freezing diagnostics into render-safe semantic-colouring overlay entries.
- Preserves diagnostic source family, severity, syntax node when available, source-line span, message, and deterministic fingerprint.
- Maps diagnostic severities only into existing syntax token buckets:
  - Diagnostic_Error
  - Diagnostic_Warning
  - Identifier for informational overlays
- Keeps rendering projection-only: no parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering-side semantic work.
- Added AUnit regression:
  - Test_Ada_Semantic_Colour_Diagnostics_Projection_Pass1041

Full compiler-grade Ada analysis remains incomplete until the remaining semantic layers such as deeper overload resolution, full type checking, generic contract closure, freezing/representation legality, cross-unit semantic closure, and diagnostic UI routing are fully integrated.
