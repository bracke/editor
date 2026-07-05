Pass1193 adds Editor.Ada_Tasking_Protected_Deep_Edge_Legality.

This pass deepens final tasking/protected legality beyond the Pass1185 final-effect row model.  It covers protected action reentrancy through indirect calls, callback reentrancy, entry-family index and queue semantics, requeue/select entry-family paths, accept-body effect paths, terminate alternative dependency graphs, task-termination ordering, abort/deferred-finalization ordering, and abortable-select finalization safety.

The new layer consumes final tasking/protected effect evidence, final flow/contract proof evidence, and final cross-unit semantic closure evidence before allowing deep edge conclusions to remain confidently legal.  Missing, blocked, stale, fingerprint-mismatched, or indeterminate evidence is preserved as an explicit blocker rather than flattened into a generic tasking error.

Added AUnit regression:
- Test_Ada_Tasking_Protected_Deep_Edge_Legality_Pass1193

This pass adds one compiler-grade building block for tasking/protected deep edge legality. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
