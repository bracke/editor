Pass1044 — semantic diagnostic index/search API

This pass adds one compiler-grade IDE integration building block for Ada semantic diagnostics.

Implemented:
- Added Editor.Ada_Semantic_Diagnostic_Index.
- Indexed snapshot-guarded unified semantic diagnostic feed entries.
- Added deterministic queries by source-line range, source position, severity, semantic source family, token kind, and syntax node.
- Preserved stale-feed rejection behavior by exposing zero indexed entries for rejected feeds.
- Preserved deterministic severity counters, rejected-entry totals, and fingerprints.
- Added AUnit regression Test_Ada_Semantic_Diagnostic_Index_Pass1044.

Invariant notes:
- No rendering-side parsing.
- No file IO.
- No buffer, dirty-state, workspace, command, keybinding, or render mutation.
- Consumes only accepted semantic diagnostic feed metadata.

Full compiler-grade Ada analysis remains incomplete until the remaining semantic layers such as overload resolution edge cases, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
