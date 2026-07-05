Pass1058 — Ada generic view-aware compatibility

This pass adds Editor.Ada_Generic_View_Compatibility, a compiler-grade building block that consumes generic object/default type conformance metadata together with view-aware compatibility metadata. It classifies generic actual/default failures as compatible, private-view barrier, limited-view barrier, cross-unit unresolved, ordinary object mismatch, object unknown, or no-view-metadata, while preserving instance/formal identity, source spans, expression text, cross-unit target/selector metadata, counters, and deterministic fingerprints.

The model is projection/analysis-only. It performs no parsing, file IO, dirty-state mutation, command registration, workspace mutation, or rendering-side semantic work. It is intended for later integration into generic contract diagnostics and instantiated-body analysis.

Regression coverage: Test_Ada_Generic_View_Compatibility_Pass1058.
