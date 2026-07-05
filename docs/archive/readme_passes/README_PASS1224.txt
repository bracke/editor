Pass1224 — Abstract/refined state consumer integration legality

This pass adds Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality.

The new layer makes abstract/refined-state evidence a mandatory prerequisite for hard semantic consumers that depend on state proof: Global/Depends refinement, dispatching effects, generic replay, representation/freezing effects, tasking/protected operations, volatile/atomic/shared-variable effects, cross-unit shared-state closure, and the shared-state stabilized closure boundary.

It preserves blocker families for abstract-state proof, shared-state evidence, overload/dispatching evidence, representation/freezing evidence, tasking/protected evidence, cross-unit evidence, stabilized-closure evidence, source-fingerprint mismatches, multiple blockers, and indeterminate rows.

Added AUnit coverage in Test_Ada_Abstract_State_Refined_State_Consumer_Integration_Legality_Pass1224 and registered it in the core suite.
