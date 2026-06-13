Pass1207 — Final semantic recheck convergence legality

This pass adds Editor.Ada_Final_Semantic_Recheck_Convergence_Legality.

The package consumes Pass1206 final semantic recheck application rows and classifies whether each final semantic result has converged, is stably withheld by an unchanged prerequisite blocker, preserves a real semantic error, remains indeterminate, or changed relative to a caller supplied prior application fingerprint.  This prevents repeated semantic rechecks from cycling on unchanged stale, AST/coverage, cross-unit, view, generic replay/backmapping, overload/type, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility/lifetime, discriminant/variant, multiple-prerequisite, and indeterminate evidence while still forcing recheck when the application fingerprint changes.

The pass adds Test_Ada_Final_Semantic_Recheck_Convergence_Legality_Pass1207 and registers it in the core AUnit suite.
