Pass1238 — Dataflow Generic Shared-State Final Legality

This pass adds one compiler-grade building block for definite-initialization and dataflow integration over the generic/shared-state final semantic chain.

New package:

  Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality

The pass connects definite initialization, dataflow/initialization consumers, predicate/dataflow consumers, predicate generic shared-state evidence, generic abstract-state replay, stabilized shared-state closure, representation/freezing generic shared-state evidence, tasking/protected generic shared-state evidence, accessibility/lifetime generic shared-state evidence, discriminant/variant generic shared-state evidence, exception/finalization generic shared-state evidence, renaming/alias shared-state evidence, and volatile/atomic representation evidence.

It classifies accepted and blocked dataflow conclusions for reads, writes, read/write effects, out and in-out parameters, return objects, variant-dependent components, access escape paths, controlled finalization paths, generic formal objects, volatile objects, atomic objects, dispatching-call effects, and cross-unit shared state.

The pass preserves blocker-family identity for definite-initialization blockers, dataflow-initialization blockers, predicate/dataflow blockers, predicate generic shared-state blockers, generic replay blockers, stabilized shared-state closure blockers, representation/freezing blockers, tasking/protected blockers, accessibility blockers, discriminant/variant blockers, exception/finalization blockers, renaming blockers, volatile/atomic representation blockers, read-before-write errors, partial component initialization, out-parameter assignment, return-object initialization, branch/loop merge failures, exceptional paths, finalization paths, access escapes, variant components, volatile/atomic effects, generic substitution, fingerprint mismatch, multiple blockers, and indeterminate states.

New regression:

  Test_Ada_Dataflow_Generic_Shared_State_Final_Legality_Pass1238

This pass adds one compiler-grade building block for definite-initialization/dataflow integration over generic/shared-state semantics. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
