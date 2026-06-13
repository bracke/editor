Pass1365 - RM Gap Burn-Down Pass 23

Added Editor.Ada_RM_Gap_Burn_Down_Pass1365 and Test_Ada_RM_Gap_Burn_Down_Pass1365.

This pass closes the semantic final readiness / release-gate gap. It turns accumulated Ada RM coverage, remediation, precision, project snapshot, consumer, diagnostic, cancellation, supersession, and budget evidence into one deterministic snapshot-level final verdict.

Final verdict states covered by the new gate:

- clean
- illegal
- legal with runtime checks
- warning-only
- indeterminate
- partial coverage
- missing checker
- cancelled
- superseded
- budget exceeded
- project-index blocked
- recovery blocked
- stale

The pass rejects:

- snapshots marked clean while partial, missing, or illegal blockers remain
- hard diagnostics emitted from indeterminate evidence
- runtime-check or warning-only evidence promoted to hard illegal
- stale, cancelled, or budget-exceeded rows consumed as current
- consumer disagreement about the final legality state
- build diagnostics conflated with internal Ada semantic diagnostics
- noncanonical entity/type/profile/unit/effect models
- unbalanced regression evidence
- nondeterministic diagnostic ordering
- unnormalized blocker families
- unstable secondary evidence or error identity churn
- missing RM coverage/remediation/consumer/project/source-shaped evidence
- stale source, AST, type, profile, unit, project-index, closure, substitution, effect, policy, recovery, consumer, or request fingerprints

The AUnit tests cover balanced final verdict rows and rejection paths for clean-state overclaiming, stale/cancelled/budget misuse, consumer/model disagreement, ordering instability, missing evidence, and fingerprint mismatch.

Registered Test_Ada_RM_Gap_Burn_Down_Pass1365 in Core_Suite.
