Pass1293 - Remaining RM edge stabilized closure diagnostic provenance

This pass implements Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Provenance.

The pass consumes Pass1292 stabilized remaining RM edge closure diagnostic rows and links each diagnostic back through the stabilized closure, stabilization gate, convergence, recheck application, recheck eligibility, remediation worklist, earlier remaining-edge diagnostic row, and original remaining-edge precision evidence.

Accepted stabilized closure rows remain current non-diagnostic semantic evidence. Emitted blockers retain exact provenance for remaining-edge blockers, stabilized direct-consumer closure blockers, source fingerprint mismatches, substitution fingerprint mismatches, multiple prerequisites, recheck-required rows, and indeterminate rows.

Added tests:
- Test_Ada_Remaining_RM_Edge_Stabilized_Closure_Diagnostic_Provenance_Pass1293

This pass adds one compiler-grade building block for remaining RM edge closure traceability. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
