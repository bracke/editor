Pass1138 - Flow-effect graph legality

This pass adds Editor.Ada_Flow_Effect_Graph_Legality.

The new package deepens Global/Depends analysis beyond independent legality rows by
building deterministic flow-effect graph edges for object reads, object writes,
read/write effects, Depends edges, call-effect propagation, generic formal/actual
effect substitution, protected-state effects, task-activation effects, and refined
Global/Depends body/spec effects.

The pass consumes Pass1123 Global/Depends legality and Pass1137 coverage-gate
enforcement. A coverage-gated or already illegal dataflow row can no longer become
a confident flow-effect result. It becomes a linked flow-effect blocker or a
coverage-gate blocker while preserving row identity, nodes, object names, source
and target names, effect kind, modes, source locations, and stable fingerprints.

The AUnit regression Test_Ada_Flow_Effect_Graph_Legality_Pass1138 checks:

* legal Global input object reads,
* writes through input-only Global items,
* missing call-effect propagation,
* generic formal/actual effect-mode mismatch,
* protected-function state-write rejection,
* task activation effects missing from Global coverage,
* Depends source/target mode validation,
* coverage-gate blockers,
* conversion of Pass1123 dataflow rows into graph edges,
* deterministic counters and fingerprints.

This pass adds one compiler-grade building block for real Global/Depends flow
graph analysis. Full compiler-grade Ada analysis remains incomplete until the
remaining Ada legality, overload/type resolution, generic, representation/freezing,
accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure
layers are fully integrated.
