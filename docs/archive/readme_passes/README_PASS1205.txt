Pass1205 — Final semantic recheck eligibility legality

This pass adds Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality.

The package consumes Pass1204 final semantic remediation worklist rows and converts them into bounded recheck eligibility rows.  It prevents downstream semantic consumers from rechecking or accepting a result while prerequisite evidence remains unresolved.

The model preserves blocker-family identity for stale snapshot evidence, parser/AST and coverage repair, cross-unit closure, view barriers, generic replay/backmapping, overload/type evidence, representation/freezing evidence, flow/contract proof, tasking/protected effects, elaboration evidence, accessibility/lifetime evidence, discriminant/variant evidence, multiple prerequisites, and indeterminate states.

AUnit coverage is provided by Test_Ada_Final_Semantic_Recheck_Eligibility_Legality_Pass1205 and registered in tests/src/core_suite.adb.
