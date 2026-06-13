Pass1231 adds Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality.

This pass adds one compiler-grade building block for cross-unit semantic closure across the generic/shared-state final chain.  It consumes cross-unit shared-state closure, generic abstract-state replay, overload/generic shared-state final evidence, representation/generic shared-state final evidence, tasking/generic shared-state final evidence, abstract-state consumer integration, and stabilized shared-state closure before accepting cross-unit generic/shared-state conclusions as current.

The pass preserves blocker-family identity for missing or blocked cross-unit shared-state evidence, generic abstract-state replay, overload/generic shared-state evidence, representation/generic shared-state evidence, tasking/generic shared-state evidence, abstract-state consumer evidence, stabilized shared-state closure, dependency failures, limited/private view barriers, child/private-child visibility, generic body availability, generic backmapping, state visibility, dispatching Global/Depends effects, volatile/atomic effects, representation effects, tasking/protected effects, source fingerprint mismatches, substitution fingerprint mismatches, multiple blockers, and indeterminate state.

Added regression:

  Test_Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality_Pass1231

This pass deliberately avoids command, palette, rendering, workspace, or diagnostic-projection work.  Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
