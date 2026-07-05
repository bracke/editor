Pass1222 - Shared-state stabilization gate legality

This pass adds Editor.Ada_Shared_State_Stabilization_Gate_Legality.

The new layer consumes Pass1221 shared-state recheck convergence rows and decides whether shared-state semantic evidence may cross the stabilization boundary.  Stable current and not-required rows are promoted; stable prerequisite blockers remain withheld with their original blocker family; changed rows require another bounded recheck; indeterminate rows remain degraded rather than becoming confident legal conclusions.

The gate preserves blocker-family identity for cross-unit dependencies, view barriers, generic backmapping, state visibility, abstract/refined state, volatile/atomic/shared-variable effects, overload shared-state evidence, representation/freezing shared-state evidence, tasking/protected shared-state evidence, source fingerprint mismatches, stale eligibility, multiple prerequisites, and indeterminate states.

Added regression:

  Test_Ada_Shared_State_Stabilization_Gate_Legality_Pass1222

This pass adds one compiler-grade building block for shared-state semantic stabilization. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
