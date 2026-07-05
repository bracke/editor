Pass1072 — Overload ranking provenance/explain metadata

This pass adds Editor.Ada_Overload_Ranking_Provenance, a projection-only model that links overload-ranking decisions with expression diagnostics. It allows IDE explain/provenance consumers to distinguish exact overload choices, implicit-conversion-ranked choices, universal numeric tie-breaks, ambiguous-after-ranking cases, rejected candidate sets, unknown ranking states, and unlinked ranking/diagnostic metadata.

The model consumes Editor.Ada_Expression_Diagnostics and Editor.Ada_Overload_Ranking. It preserves ranking identity, expression diagnostic identity, syntax node, severity, stable span, candidate/exact/implicit/universal/rejected/unknown/selected counts, ranking and diagnostic fingerprints, explanation text, stage counters, and deterministic result fingerprints.

No parsing, file IO, buffer mutation, command registration, workspace mutation, rendering-side semantic work, or edit application is introduced.

This pass adds one compiler-grade building block for overload-ranking provenance and IDE explanation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
