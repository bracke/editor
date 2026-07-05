Pass1226 — Dispatching Global/Depends refinement legality

This pass adds Editor.Ada_Dispatching_Global_Refinement_Legality.

The new layer connects dispatching-call Global/Depends proof to the shared-state semantic chain. It covers class-wide controlling calls, controlling operations, inherited primitives, prefixed dispatching calls, interface dispatching calls, renamed dispatching primitives, access-to-class-wide dispatch, generic formal dispatching operations, dynamic effect joins, and abstract-state joins.

It consumes final flow/contract proof, abstract/refined-state legality, abstract/refined-state consumer integration, overload shared-state RM evidence, volatile/atomic representation consumer evidence where required, and shared-state stabilized closure evidence before accepting dispatching effect conclusions. It preserves blocker families for flow/contract proof, abstract state, abstract-state consumers, overload shared-state evidence, volatile/atomic representation evidence, stabilized shared-state closure, Global mode mismatches, Depends edge mismatches, dynamic effect joins, inherited primitive hiding, renamed primitive effects, generic formal effects, source fingerprint mismatches, multiple blockers, and indeterminate rows.

Added AUnit coverage in Test_Ada_Dispatching_Global_Refinement_Legality_Pass1226 and registered it in the core suite.
