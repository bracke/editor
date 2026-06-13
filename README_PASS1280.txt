Pass1280: RM-completion closure consumer stabilized closure

This pass adds Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality.

It consumes Pass1279 RM-completion closure consumer stabilization-gate rows and turns stable direct-consumer conclusions into first-class semantic closure evidence. Promoted current and promoted not-required rows become accepted closure evidence. Stable withheld rows become explicit closure blockers while preserving their original prerequisite family. Recheck-required rows remain outside accepted closure so changed evidence cannot be trusted by downstream consumers.

The pass preserves blocker-family identity for cross-unit closure, elaboration, accessibility/lifetime, exception/finalization, overload/type, representation/freezing, tasking/protected, dataflow/initialization, predicate/invariant, AST/coverage, generic substitution, source/substitution fingerprint mismatch, multiple prerequisites, and indeterminate states.

Added AUnit coverage in Test_Ada_RM_Completion_Closure_Consumer_Stabilized_Closure_Legality_Pass1280 and registered it in the core suite.
