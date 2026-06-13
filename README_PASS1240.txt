Pass1240: Generic/shared-state final remediation worklist legality

This pass adds Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality.

The package consumes Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration and converts blocker-preserving generic/shared-state final diagnostic rows into a deterministic semantic remediation worklist. Accepted rows remain current semantic evidence. Blocking rows become prerequisite work items before downstream re-analysis may trust generic/shared-state conclusions.

The worklist preserves semantic blocker-family identity for definite initialization, dataflow initialization, predicate/dataflow, predicate generic/shared-state, generic abstract-state replay, stabilized shared-state closure, representation/freezing generic shared-state, tasking/protected generic shared-state, accessibility/lifetime, discriminants/variants, exception/finalization, renaming/aliasing, volatile/atomic representation, local Ada dataflow RM legality, source/substitution fingerprint mismatch, multiple blockers, and indeterminate state.

The package exposes deterministic counts, action/family/priority/node/source-fingerprint queries, downstream-blocking state, current-evidence state, recheck readiness, and stable fingerprints.

Added AUnit regression:

Test_Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality_Pass1240

This pass adds one compiler-grade building block for generic/shared-state final semantic convergence. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
