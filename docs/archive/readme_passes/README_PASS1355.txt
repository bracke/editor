Pass1355 - RM Gap Burn-Down Pass 13

Implemented Editor.Ada_RM_Gap_Burn_Down_Pass1355.

This pass burns down the call-site composition gap where actual/formal
association, parameter modes, defaulted formals, callable profiles, overload
results, null exclusions, accessibility, writable-actual aliasing, dispatching,
generic substitution, renaming, access-to-subprogram calls, contracts, flow
effects, warning-only policy evidence, and editor semantic consumers must agree
on one canonical source-shaped Ada result.

The pass adds source-shaped rows and blocker families for:

- positional, named, mixed, duplicate, missing, extra, and defaulted actuals
- out and in out variable-view requirements
- constant-view and limited-view writable actual rejection
- out-parameter definite-assignment evidence
- formal/actual type and access-parameter compatibility
- anonymous access actual compatibility
- null-exclusion and static accessibility violations
- runtime accessibility/range/predicate check preservation
- callable-profile and overload-profile agreement
- writable-actual aliasing and overlapping writable actuals
- access-value aliasing evidence
- volatile/atomic and protected/shared-state call effects
- dispatching controlling operand/result evidence
- generic formal subprogram substitution profile preservation
- renamed callable profile preservation
- access-to-subprogram convention compatibility
- Pre/Post, Global/Depends, refined-flow, and dispatching-effect preservation
- hard policy versus warning-only policy classification
- diagnostics, semantic-colouring, outline, navigation, hover/detail, and build
  bridge consumer agreement
- stale source, AST, call, association, type, profile, overload, substitution,
  effect, alias, and consumer fingerprints

Added AUnit coverage in Test_Ada_RM_Gap_Burn_Down_Pass1355 and registered it in
Core_Suite.  The tests include legal, illegal, runtime-check, warning-only,
indeterminate, consumer-surfaced, and fingerprint-stale scenarios so the RM
coverage/remediation state can be promoted only with balanced source-shaped
evidence.
