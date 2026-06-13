Pass1123: Global / Depends dataflow legality integration

This pass adds one compiler-grade building block for Ada Global/Depends dataflow legality.

Implemented:

- Added Editor.Ada_Dataflow_Global_Depends_Legality.
  - Connects Global/Depends contract-aspect facts with flow-sensitive definite-initialization object-state facts.
  - Classifies read, write, read/write, null-effect, Depends-edge, and refinement effects.
  - Enforces Global mode coverage for reads and writes:
    - reads require Global in / in out / proof in coverage,
    - writes require Global out / in out coverage,
    - null Global rejects any read/write effect,
    - Global in rejects writes,
    - Global out rejects reads.
  - Enforces Depends edge consistency:
    - missing source,
    - source not covered by an input mode,
    - target not covered by an output mode,
    - duplicate edges,
    - cycles,
    - unresolved edges.
  - Consumes definite-initialization legality so read-before-write, out-parameter assignment failures, conditional in out assignment, and use-after-finalization become dataflow legality errors rather than isolated flow facts.
  - Preserves linked contract and initialization failures when the source Global/Depends or object-state legality is already invalid.
  - Provides deterministic counters, lookups, result sets, and fingerprints for status, kind, effect, object, node, Global errors, Depends errors, initialization errors, linked errors, and indeterminate rows.
- Added Closure_Blocker_Dataflow and Integrated_Closure_Dataflow_Blocker to Editor.Ada_Integrated_Semantic_Closure.
- Added Dataflow_Error to Integrated_Closure_Context_Info.
- Added Editor.Ada_Integrated_Semantic_Closure.Dataflow.
  - Build_With_Dataflow converts Global/Depends dataflow legality rows into integrated closure contexts.
  - Legal dataflow rows remain legal closure rows.
  - Non-legal dataflow rows become first-class integrated closure blockers and flow through the existing diagnostic feed, diagnostic index, and provenance path.
- Extended unified semantic diagnostic feed source/status handling for dataflow closure blockers.
- Added Test_Ada_Dataflow_Global_Depends_Legality_Pass1123 and registered it in tests/src/core_suite.adb.

The regression validates that Global mode violations, Depends mode violations, initialization-before-read failures, and linked contract flow errors are classified together; that counters distinguish Global, Depends, initialization, and linked failures; and that dataflow blockers enter integrated closure, diagnostic feed, diagnostic index, and provenance without creating a projection-only layer.

This pass is intentionally a widened semantic integration pass. It connects contract aspects, object-state flow, Global/Depends dataflow effects, integrated closure, unified diagnostics, and provenance around actual Ada legality.

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
