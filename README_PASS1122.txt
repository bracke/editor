Pass1122: Definite-initialization integrated semantic closure

This pass adds one compiler-grade building block for Ada definite-initialization and flow-sensitive object-state legality integration.

Implemented:

- Added Closure_Blocker_Definite_Initialization and Integrated_Closure_Definite_Initialization_Blocker to Editor.Ada_Integrated_Semantic_Closure.
- Added Initialization_Error to Integrated_Closure_Context_Info so definite-initialization failures participate as first-class semantic closure blockers rather than remaining a parallel legality model.
- Added Editor.Ada_Integrated_Semantic_Closure.Definite_Initialization.
  - Build_With_Definite_Initialization copies existing closure contexts.
  - Converts Pass1121 definite-initialization/flow legality rows into integrated closure contexts.
  - Preserves node, object node, object name, context kind, spans, status class, source fingerprint, and row fingerprint through the closure model.
  - Maps legal initialization proofs to legal local closure rows.
  - Maps read-before-write, component read-before-write, partial initialization, out-parameter obligations, return-object obligations, branch/loop merge failures, exception/finalization path losses, use-after-finalization, and linked flow errors to definite-initialization closure blockers.
  - Maps indeterminate initialization rows to integrated indeterminate closure rows.
- Extended the unified semantic diagnostic feed source/status handling so initialization closure blockers flow through Build_With_Integrated_Closure without a separate projection chain.
- Extended diagnostic provenance labels so integrated-closure provenance can name definite-initialization/flow blockers.
- Added Test_Ada_Integrated_Closure_Definite_Initialization_Pass1122 and registered it in tests/src/core_suite.adb.

The regression validates that definite-initialization legality rows enter integrated closure, non-legal rows enter the unified diagnostic feed, the diagnostic index can query them by node, provenance links diagnostics back to closure rows, and fingerprints include the initialization flow rows.

This pass is intentionally not a UI/projection-only pass. It connects a real Ada legality layer into the integrated semantic closure consumed by diagnostics and provenance.

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
