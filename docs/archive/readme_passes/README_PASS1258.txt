Pass1258 — Coverage-proven RM-completion AST repair legality

This pass adds one compiler-grade building block for coverage-proven AST repair after the generic/shared-state RM-completion chain.

New package:
  Editor.Ada_Coverage_Proven_RM_Completion_AST_Repair_Legality

Purpose:
  Classify parser/AST repair as a trusted semantic prerequisite only when coverage gates prove that a real RM-completed generic/shared-state legality consumer remains blocked by parser-node gaps, structural AST gaps, token-only parse paths, missing source spans, missing metadata, or missing consumer integration.

Consumed evidence:
  * semantic coverage gates
  * generic/shared-state stabilized closure
  * overload/type RM edge completion
  * representation/freezing RM hard-case completion
  * tasking/protected RM hard-case completion
  * cross-unit generic/shared-state RM-completion closure
  * elaboration/accessibility/exception-finalization/predicate/dataflow RM-completion consumers
  * RM-completion diagnostic integration
  * RM-completion remediation worklist

The pass preserves blocker-family identity for missing gates, gates that do not prove repair need, parser-node gaps, structural AST gaps, token-only parse paths, source-span gaps, metadata gaps, consumer-integration gaps, source fingerprint mismatches, RM-completion prerequisite blockers, multiple blockers, and indeterminate states.

Added regression:
  Test_Ada_Coverage_Proven_RM_Completion_AST_Repair_Legality_Pass1258

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
