Pass1204 - Final semantic remediation worklist legality

This pass adds Editor.Ada_Final_Semantic_Remediation_Worklist_Legality.

The package consumes Pass1203 final semantic remediation diagnostic provenance/search rows and converts prerequisite blocker evidence into a deterministic semantic re-analysis worklist. It is not a command, palette, status, or render projection layer. The worklist is a compiler-grade ordering model for prerequisite semantic repairs.

The worklist preserves blocker-family identity for stale snapshot evidence, AST and coverage repair, cross-unit closure, view barriers, generic replay and backmapping, overload/type evidence, representation/freezing evidence, flow/contract proof, tasking/protected effects, elaboration closure, accessibility/lifetime evidence, discriminant/variant evidence, preserved semantic errors, multiple blockers, and indeterminate states.

The model exposes stable rows, actions, phases, priorities, dependency depths, node/span/fingerprint data, counters, queries, and a deterministic model fingerprint. Downstream semantic consumers can use this worklist to avoid rechecking conclusions before prerequisite blockers have been resolved.

Added AUnit regression:
Test_Ada_Final_Semantic_Remediation_Worklist_Legality_Pass1204
