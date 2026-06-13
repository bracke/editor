Pass1230 adds Editor.Ada_Tasking_Generic_Shared_State_Final_Legality.

This pass adds one compiler-grade building block for tasking/protected legality across generic replay and shared-state evidence.  It consumes deep tasking/protected evidence, tasking shared-state final evidence, generic abstract-state replay, overload/generic shared-state evidence, representation/generic shared-state evidence, abstract-state consumer integration, and stabilized shared-state closure before accepting tasking/protected conclusions as current.

The pass preserves blocker-family identity for missing or blocked deep tasking evidence, tasking shared-state evidence, generic abstract-state replay, overload/generic shared-state evidence, representation/generic shared-state evidence, abstract-state consumer evidence, stabilized shared-state closure, protected-action reentrancy, entry-family queue semantics, accept/requeue/select paths, task activation/termination, abort/finalization, generic body effects, representation-sensitive tasking effects, source fingerprint mismatches, substitution fingerprint mismatches, multiple blockers, and indeterminate state.

Added regression:

  Test_Ada_Tasking_Generic_Shared_State_Final_Legality_Pass1230

This pass deliberately avoids command, palette, rendering, workspace, or diagnostic-projection work.  Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
