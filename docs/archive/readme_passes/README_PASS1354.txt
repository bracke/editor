Pass1354 — RM Gap Burn-Down Pass 12

Implemented Editor.Ada_RM_Gap_Burn_Down_Pass1354.

This pass burns down the declaration-region / scope / completion / homograph / renaming / alias lifecycle gap. It enforces one canonical source-shaped result across declarative regions, nested scopes, package/subprogram/task/protected/generic bodies, homograph and hiding rules, private and incomplete type completions, deferred constants, body/spec completion, renamings, alias chains, and semantic consumers.

The pass rejects duplicate non-overloadable declarations, overloadable homographs collapsed into duplicate errors, hiding/use-visible conflict disagreement, private/full-view disagreement, incomplete types used as complete before completion, deferred constants without valid completion, body/spec mismatches, duplicate or missing completions, renaming target/profile/view mismatches, alias cycles/depth overflow, cross-slice entity/view disagreement, stale declaration/scope/completion/alias/view fingerprints, and consumer-local interpretations.

Added AUnit coverage in Test_Ada_RM_Gap_Burn_Down_Pass1354 and registered it in Core_Suite.
