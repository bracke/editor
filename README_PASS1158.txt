Pass1158 — Tasking / protected elaboration contract-flow consumer legality

This pass adds Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality.

Purpose

Pass1158 connects elaboration-time Global / Depends and Refined_Global / Refined_Depends contract-flow evidence into tasking/protected effect legality. Task activation, task termination, protected reads/writes, protected subprogram and entry calls, entry queue effects, entry barriers, accept bodies, requeue, select guards and alternatives, abortable parts, delay alternatives, and terminate alternatives no longer remain confidently legal when their matching elaboration contract-flow evidence is missing, blocked, or indeterminate.

Semantic inputs

The package consumes:

- Editor.Ada_Tasking_Protected_Effects_Legality
- Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality

Statuses include:

- legal task activation / task termination / protected operation / entry / accept / requeue / select / delay / terminate acceptance
- base tasking/protected effect error
- missing elaboration contract-flow row
- Refined_Global missing read/write
- Refined_Global mode mismatch / extra item
- Refined_Depends missing/extra edge
- Refined_Depends source/target mode errors
- call effect not propagated
- repaired coverage feedback blocker
- linked flow graph error
- base contract-flow error
- base elaboration error
- multiple elaboration contract-flow blockers
- indeterminate elaboration contract-flow

Why this is semantic progress

The earlier tasking/protected effects checker could already classify task/protected semantic effects, and Pass1157 could classify elaboration contract-flow blockers. Pass1158 makes those layers interact: a tasking/protected effect is not considered confidently legal merely because the local tasking rule passes if its elaboration-time refined Global/Depends evidence is blocked.

Regression

Added Test_Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality_Pass1158 and registered it in tests/src/core_suite.adb.
