Pass1121 — Definite Initialization / Flow Legality

This pass adds Editor.Ada_Definite_Initialization_Flow_Legality, a widened compiler-grade semantic building block for Ada definite initialization and flow-sensitive object state legality.

The new package is snapshot-owned and projection-free. It consumes already-resolved semantic facts and linked statuses from assignment legality, return legality, control-flow legality, exception/finalization legality, and integrated semantic closure. It does not parse, save, reload, mutate dirty state, register commands, change keybindings/workspace state, or perform render-side analysis.

Coverage added:

* definite/default/explicit object initialization classification
* component initialization and partial component coverage
* read-before-write and component read-before-write detection
* out-parameter assignment obligations
* in out conditional-assignment metadata
* return-object and extended-return initialization obligations
* branch merge and loop-carried initialization proof failures
* exception-path initialization loss
* finalization use of uninitialized objects
* use-after-finalization metadata
* unreachable initialization metadata
* linked assignment/return/control-flow/exception-finalization/integrated-closure blockers
* deterministic counters, lookups, and fingerprints

AUnit:

* Test_Ada_Definite_Initialization_Flow_Legality_Pass1121
* Registered in tests/src/core_suite.adb

This pass adds one compiler-grade building block for flow-sensitive definite-initialization legality. Full compiler-grade Ada analysis still requires deeper flow graph construction, path-sensitive dataflow, discriminant-dependent component initialization, task/protected concurrent initialization effects, and complete integration with the parser-owned semantic pipeline.
