Pass1248: tasking/protected RM hard-case completion for the stabilized generic/shared-state chain

This pass adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality.

The pass consumes Pass1230 tasking/generic/shared-state final legality, Pass1245 stabilized generic/shared-state closure, Pass1246 overload RM edge completion, and Pass1247 representation/freezing RM hard-case completion. It preserves tasking/protected blocker families for protected action reentrancy, callback reentrancy, entry-family queue legality, requeue/select paths, accept-body effects, abort/finalization ordering, task termination ordering, protected shared-state access, abstract-state-backed task effects, and generic task/protected body effects.

Accepted rows become non-blocking only when previous tasking evidence, representation hard-case evidence, overload edge evidence, stabilized closure evidence, and source/substitution fingerprints agree. Missing or blocked prerequisites remain explicit blockers.

Added AUnit regression:
Test_Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality_Pass1248
