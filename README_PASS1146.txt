Pass1146 — Representation / freezing exact propagation legality

This pass adds Editor.Ada_Representation_Freezing_Exact_Propagation_Legality.

The pass deepens the representation/freezing work from Pass1131 by propagating implicit freezing caused by semantic uses and by connecting those freezing effects to the widened semantic layers added after Pass1131.

Compiler-grade building block added:

- Explicit propagation of freezing caused by expression use, call use, object declarations, subprogram bodies, generic instances, instantiated generic body replay, private/full-view completion, discriminant/variant representation, operational attributes, stream attributes, finalization effects, elaboration edges, and tasking/protected effects.
- Representation clauses/items are classified against those propagated freezing points.
- Generic instance freezing and generic body replay freezing are separated so diagnostics can preserve whether the freezing came from the instance boundary or replayed body content.
- Discriminant and variant representation errors are linked into freezing decisions.
- Operational, stream, and finalization effects participate in representation/freezing legality.
- Flow-effect, predicate/invariant, accessibility scope, elaboration graph, tasking/protected effect, and coverage-gate blockers are preserved rather than collapsed.
- Multiple blockers remain distinct as a multiple-blocker classification.
- Deterministic counters, lookups, source fingerprints, row fingerprints, and stable model fingerprints were added.

Regression coverage:

- Test_Ada_Representation_Freezing_Exact_Propagation_Legality_Pass1146
- Registered in tests/src/core_suite.adb

This pass continues the widened semantic direction: it adds a compiler-grade building block for representation/freezing exact propagation. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
