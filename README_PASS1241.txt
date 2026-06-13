Pass1241 — Generic/shared-state final recheck eligibility legality

This pass adds Editor.Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality.

The package consumes the Pass1240 generic/shared-state final remediation worklist and converts ordered prerequisite work into bounded recheck eligibility rows.  It prevents downstream generic/shared-state final consumers from accepting conclusions while prerequisite evidence remains unresolved, including generic abstract-state replay, stabilized shared-state closure, volatile/atomic representation, representation/freezing, tasking/protected, accessibility/lifetime, discriminants/variants, exception/finalization, renaming/aliasing, predicates/invariants, dataflow, source/substitution fingerprints, multiple blockers, and indeterminate state.

The model exposes deterministic row counts, status/action/family/node/source-fingerprint queries, blocker-family counters, priority ranks, and stable eligibility fingerprints.  Current accepted evidence is preserved as non-required recheck evidence; blocking worklist rows remain explicit blockers rather than being collapsed into a generic diagnostic category.

Regression coverage:

* Test_Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality_Pass1241
* tests/src/core_suite.adb registration

This pass adds one compiler-grade building block for generic/shared-state final semantic convergence.  Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
