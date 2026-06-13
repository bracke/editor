Pass1239 — Generic/shared-state final diagnostic integration

This pass adds Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration and extends Editor.Ada_Semantic_Diagnostic_Feed with Build_With_Generic_Shared_State_Final_Diagnostics.

The pass consumes Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality and feeds the completed generic/shared-state final semantic chain into a diagnostic/feed boundary. Accepted rows are withheld as current non-diagnostic semantic evidence. Blocking rows are emitted with their original blocker-family identity preserved for definite initialization, dataflow initialization, predicate/dataflow, predicate generic shared-state, generic abstract replay, stabilized shared-state closure, representation/freezing, tasking/protected, accessibility, discriminant/variant, exception/finalization, renaming/alias, volatile/atomic representation, local dataflow RM errors, fingerprint mismatches, multiple blockers, and indeterminate states.

The package preserves deterministic row identity, node/source-fingerprint lookup, severity counts, emitted/withheld counts, indeterminate counts, and stable diagnostic fingerprints. The semantic diagnostic feed rejects stale generic/shared-state diagnostic input instead of exposing stale rows.

Added regression:
Test_Ada_Generic_Shared_State_Final_Diagnostic_Integration_Pass1239

This pass adds one compiler-grade building block for exposing the generic/shared-state final semantic chain without flattening semantic blocker families. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
