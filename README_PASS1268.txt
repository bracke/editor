Pass1268 implements Editor.Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality.

This pass adds one compiler-grade building block for cross-unit RM-completion semantic closure.  Cross-unit consumers now require the Pass1263 generic/shared-state RM-completion stabilized closure directly before accepting completed cross-unit conclusions.  The pass preserves blocker-family identity for dependency failures, limited/private view barriers, private-child visibility, separate-body linkage, generic body availability, generic backmapping, state visibility, source and substitution fingerprint mismatches, prior cross-unit RM-completion blockers, stabilized closure blockers, multiple blockers, and indeterminate closure.

The new AUnit test package is Test_Ada_Cross_Unit_RM_Completion_Closure_Consumer_Legality_Pass1268.  It verifies acceptance only when prior cross-unit RM evidence and stabilized RM-completion closure agree, preservation of blocker families, deterministic lookup by node/unit/source fingerprint, and stable fingerprints.

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
