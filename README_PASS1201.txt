Pass1201 — Final semantic remediation closure legality

This pass adds Editor.Ada_Final_Semantic_Remediation_Closure_Legality.

The package consumes Pass1200 final semantic remediation gates and feeds them back into a deterministic closure model.  Unresolved prerequisite gates become first-class semantic closure blockers, so downstream consumers cannot bypass stale snapshot evidence, AST/coverage gaps, cross-unit dependency failures, view barriers, generic replay failures, overload/type blockers, representation/freezing blockers, flow/contract proof blockers, tasking/protected blockers, elaboration blockers, accessibility/lifetime blockers, or discriminant/variant blockers.

Legal gates remain confident local closure rows.  Preserved semantic errors remain hard closure blockers.  Indeterminate gates remain indeterminate closure.  The model keeps source nodes, spans, blocker families, dependency order, downstream blocked pressure, source fingerprints, gate fingerprints, and deterministic closure fingerprints.

AUnit coverage:

- Test_Ada_Final_Semantic_Remediation_Closure_Legality_Pass1201

This pass is a compiler-grade semantic integration step, not a projection/status/UI layer.
