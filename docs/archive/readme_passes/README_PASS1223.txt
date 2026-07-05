Pass1223 - Shared-state stabilized closure legality

This pass adds Editor.Ada_Shared_State_Stabilized_Closure_Legality.

The new layer consumes Pass1222 shared-state stabilization-gate rows and turns stable shared-state conclusions into first-class shared-state closure rows.  Stable accepted rows become current semantic evidence.  Stable prerequisite blockers remain closure blockers with their original blocker-family identity.  Recheck-required and indeterminate rows are not exposed as confident shared-state closure conclusions.

The stabilized closure preserves blocker-family identity for cross-unit dependencies, view barriers, generic backmapping, state visibility, abstract/refined state, volatile/atomic/shared-variable effects, overload shared-state evidence, representation/freezing shared-state evidence, tasking/protected shared-state evidence, source fingerprint mismatches, stale eligibility, multiple prerequisites, and indeterminate states.

Added regression:

  Test_Ada_Shared_State_Stabilized_Closure_Legality_Pass1223

This pass adds one compiler-grade building block for shared-state semantic stabilization. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
