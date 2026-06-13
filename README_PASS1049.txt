Pass1049 - Ada diagnostic provenance / explain model

This pass adds Editor.Ada_Diagnostic_Provenance.

Highlights:
- Consumes Editor.Ada_Semantic_Diagnostic_Index.
- Exposes deterministic provenance/explain items for accepted guarded semantic diagnostics.
- Preserves diagnostic identity, feed/index identity, source span, severity, source family, token kind, syntax node, message payload, source fingerprint, diagnostic fingerprint, source-chain summary, and deterministic fingerprint.
- Provides diagnostic-identity lookup through First_For_Diagnostic and Items_For_Diagnostic.
- Adds counters for errors, warnings, infos, rejected items, source families, and provenance stages.
- Rejected/stale indexes expose zero active provenance items while preserving rejected totals.
- Adds AUnit regression coverage through Test_Ada_Diagnostic_Provenance_Pass1049.

This pass is projection-only: it does not parse, perform file IO, mutate buffers, register commands, touch workspace state, generate edits, or perform rendering-side semantic work.
