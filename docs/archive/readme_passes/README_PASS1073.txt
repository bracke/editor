Pass1073 — Unified diagnostic provenance with overload-ranking explanation

This pass extends Editor.Ada_Diagnostic_Provenance so the general IDE diagnostic explain model can consume Editor.Ada_Overload_Ranking_Provenance.  Build_With_Overload_Ranking preserves the existing snapshot-guarded diagnostic-index provenance chain and adds matched overload-ranking explanation items for expression diagnostics whose syntax node, stable span, and diagnostic fingerprint match ranking provenance metadata.

The pass preserves diagnostic/index/feed identity, source span, severity, semantic source family, token kind, syntax node, source fingerprint, diagnostic fingerprint, overload-ranking provenance identity, ranking outcome, ranking candidate/selected/rejected/unknown counts, ranking fingerprint, chain summary text, and deterministic fingerprints.

Rejected/stale semantic diagnostic indexes still expose no active provenance entries.  The ranking integration is projection-only and does not parse, perform file IO, mutate buffers, register commands, touch workspace state, apply edits, or perform rendering-side semantic work.

Regression coverage: Test_Ada_Diagnostic_Provenance_Overload_Ranking_Pass1073.

This pass adds one compiler-grade building block for unified IDE diagnostic provenance and overload-ranking explanation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
