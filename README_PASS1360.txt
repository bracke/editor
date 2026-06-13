Pass1360 - Partial Source / Recovery Semantic Closure Burn-Down

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1360 and its AUnit
coverage.  It is the eighteenth RM gap burn-down pass after the vertical
semantic slices and post-slice integration/audit work.

The pass closes the live-editor partial-source recovery gap.  Whole source
unit closure from Pass1359 assumes sufficient evidence; this pass verifies the
opposite side of the editor problem: missing tokens, degraded constructs,
token-only constructs, partial declarations, partial bodies, partial aggregates,
partial calls, partial expressions, unfinished context clauses, unfinished
generic instantiations, and unfinished subunit stubs must produce canonical
indeterminate/blocker states instead of false hard legality diagnostics.

The package models source-shaped recovery rows with canonical RM family,
remediation, consumer, precision, source-kind, recovery-context, and freshness
evidence.  It rejects hard diagnostics from incomplete evidence, partial
declarations or bodies treated as complete, stale recovery results reused after
AST recovery changes, incomplete calls diagnosed as overload failures,
incomplete aggregates diagnosed as missing components, partial private/full
views treated as definitive, consumers hiding indeterminate states, semantic
colouring/navigation/hover inventing facts, and build diagnostic bridge rows
that conflate recovered internal source evidence with external diagnostics.

The tests cover balanced legal, illegal, runtime-check, and indeterminate
recovery rows; parser recovery blockers; partial unit closure degradation;
consumer degradation without invented facts; stale recovery fingerprint
rejection; and stable diagnostic blocker-family requirements.
