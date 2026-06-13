Pass1196 - Final semantic diagnostic provenance

This pass adds Editor.Ada_Final_Semantic_Diagnostic_Provenance.

The package preserves the semantic origin of Pass1194 final diagnostic rows after Pass1195 unified diagnostic feed/index insertion.  It is intentionally not a UI projection/status layer: it records the final diagnostic row, blocker family, original final status, node/span, source and diagnostic fingerprints, optional feed/index/base-provenance links, and stale/withheld decisions.

Blocker families preserved by this pass include cross-unit closure, overload/type final RM consumers, nested generic replay closure, representation/freezing final hard cases, flow/contract final proof, tasking/protected deep edge semantics, elaboration final consumers, accessibility/lifetime final consumers, discriminant/variant consumers, AST repair, coverage gates, view barriers, multiple blockers, stale inputs, and indeterminate states.

The pass adds Test_Ada_Final_Semantic_Diagnostic_Provenance_Pass1196 and registers it in tests/src/core_suite.adb.

This pass adds one compiler-grade building block for final semantic diagnostic traceability. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
