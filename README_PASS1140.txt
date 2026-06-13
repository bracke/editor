Pass1140 - Generic instance body semantic replay

This pass adds Editor.Ada_Generic_Instance_Body_Semantic_Replay.

The new package deepens the Pass1125 generic instance body expansion layer by
recording replay contexts for substituted generic body declarations,
statements, expressions, calls, flow effects, predicate/invariant obligations,
accessibility obligations, representation/freezing effects, and nested generic
instances.  Replay rows preserve both the generic-source node and the instance
node together with formal/actual names and stable fingerprints, so diagnostics
can be mapped back to the generic body and the instantiation site.

The replay model consumes existing widened semantic results: generic body
expansion, overload preference legality, flow-effect graph legality,
predicate/invariant propagation legality, accessibility precision legality,
representation/freezing precision legality, and coverage-gate enforcement.
Coverage-gate blockers and missing source/instance/formal/actual/backmap
metadata prevent confident replay conclusions.

Added AUnit coverage:

* Test_Ada_Generic_Instance_Body_Semantic_Replay_Pass1140

This pass adds one compiler-grade building block for generic instance body
semantic replay.  Full compiler-grade Ada analysis remains incomplete until the
remaining Ada legality, overload/type resolution, generic, representation/
freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit
semantic closure layers are fully integrated.
