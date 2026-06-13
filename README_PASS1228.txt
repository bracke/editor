Pass1228 - Overload/generic shared-state final legality

This pass adds Editor.Ada_Overload_Generic_Shared_State_Final_Legality.

The pass consumes the final overload shared-state RM edge layer, generic abstract-state replay, dispatching Global/Depends refinement, volatile/atomic representation consumer evidence, abstract-state consumer evidence, and stabilized shared-state closure evidence. It prevents overload/type conclusions for prefixed calls, dispatching calls, access-to-subprogram calls, class-wide controlling-result selections, inherited or renamed primitives, generic formal subprogram calls, universal numeric operators, abstract-state effects, and volatile/atomic effects from becoming confidently legal while their generic replay, shared-state, representation, dispatching, abstract-state, closure, or fingerprint prerequisites remain unresolved.

The package preserves blocker-family identity for overload shared-state blockers, generic abstract-state replay blockers, dispatching Global blockers, volatile/atomic representation blockers, abstract-state consumer blockers, stabilized shared-state closure blockers, access-profile effect mismatches, dispatching-effect mismatches, controlling-result state mismatches, universal numeric state ambiguities, source fingerprint mismatches, substitution fingerprint mismatches, multiple blockers, and indeterminate rows.

Added regression:

Test_Ada_Overload_Generic_Shared_State_Final_Legality_Pass1228

This pass adds one compiler-grade building block for final overload/type RM edge handling across generic abstract-state replay and shared-state closure. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
