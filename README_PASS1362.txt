Pass1362 - RM Gap Burn-Down Pass 20: bounded semantic work, cancellation, supersession, and deterministic scheduling

Implemented Editor.Ada_RM_Gap_Burn_Down_Pass1362.

This pass closes the live-editor bounded-work gap that remained after pass1361's incremental invalidation work. It enforces that Ada semantic analysis is snapshot-owned, budgeted, cancellable, supersession-aware, deterministic, and safe under editor invariants.

The pass adds a source-shaped burn-down model for:

- per-buffer, per-request, and per-slice semantic budgets
- bounded overload candidate exploration
- bounded generic body replay
- bounded cross-unit semantic closure
- cancellation by newer request tokens/source revisions
- superseded partial result rejection
- diagnostic suppression after cancellation
- graceful budget exhaustion as indeterminate evidence
- preservation of partial evidence already proven
- deterministic work ordering
- deterministic blocker ordering
- deterministic diagnostic ordering
- deterministic outline/navigation ordering
- rejection of hash-order/timing-dependent ordering
- consumer enforcement for cancellation and budget state
- editor invariant protection: no save/reload, dirty-state mutation, rendering-side parsing, or command/keybinding/workspace/render mutation leaks
- source/AST/type/profile/unit/substitution/effect/policy/recovery/schedule/consumer fingerprint freshness

Added AUnit coverage in Test_Ada_RM_Gap_Burn_Down_Pass1362 for:

- balanced bounded scheduling closure
- work budget enforcement
- cancellation and supersession consumer gates
- deterministic ordering requirements
- budget exhaustion degrading to indeterminate
- invariant and fingerprint enforcement

Registered the test case in Core_Suite.
