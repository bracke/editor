Pass1199: Final semantic blocker remediation ordering

This pass adds Editor.Ada_Final_Semantic_Blocker_Remediation_Order.

The new package consumes Pass1198 final semantic blocker trace closure and derives a deterministic remediation order for semantic debugging.  It is not a UI quick-fix or projection layer: it records which compiler-grade semantic evidence must be restored first before downstream legality engines may trust their conclusions.

The ordering preserves final blocker families for stale snapshot evidence, AST/coverage repair, cross-unit dependency closure, view barriers, generic replay/backmapping, overload/type evidence, representation/freezing, flow/contract proof, tasking/protected effects, elaboration, accessibility/lifetime, discriminants/variants, multiple blockers, preserved errors, and indeterminate states.

The package exposes action/status/priority queries, node/span queries, first blocking action selection, downstream unlock pressure, blocker-family counts, and stable fingerprints.

Added regression:

  Test_Ada_Final_Semantic_Blocker_Remediation_Order_Pass1199

This pass adds one compiler-grade building block for final semantic debugging and dependency ordering. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
