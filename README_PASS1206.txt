Pass1206 — Final semantic recheck application legality

This pass adds Editor.Ada_Final_Semantic_Recheck_Application_Legality.

The package consumes Pass1205 final semantic recheck eligibility rows and applies them back into the final semantic closure/feed boundary.  A semantic result is exposed as current only when its prerequisite recheck chain is eligible now.  Stale snapshots, AST/coverage gaps, cross-unit dependency failures, view barriers, generic replay/backmapping blockers, overload/type blockers, representation/freezing blockers, flow/contract proof blockers, tasking/protected blockers, elaboration blockers, accessibility/lifetime blockers, discriminant/variant blockers, preserved semantic errors, multiple prerequisites, and indeterminate states remain explicit withheld-current rows.

The pass adds Test_Ada_Final_Semantic_Recheck_Application_Legality_Pass1206 and registers it in the core AUnit suite.
