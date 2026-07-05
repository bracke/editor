Pass1353 - RM Gap Burn-Down Pass 11

Implemented package:
  Editor.Ada_RM_Gap_Burn_Down_Pass1353

Implemented tests:
  Test_Ada_RM_Gap_Burn_Down_Pass1353

This pass burns down the allocator / storage-pool / access-lifetime /
uncontrolled-operation composition gap.  The pass requires a single canonical
source-shaped result across allocator forms, storage-pool/storage-size evidence,
access conversions, static and runtime accessibility classification, access
discriminants, anonymous access assignment, generic access actual substitution,
Unchecked_Conversion, Unchecked_Deallocation, controlled/finalized allocation
hazards, allocation restriction policy, warning-only allocation policy, and
semantic consumer surfacing.

The checker preserves legal, hard-illegal, legal-with-runtime-check,
warning-only, and indeterminate states.  It rejects stale source/AST/type/profile
/substitution/effect/policy/storage-pool/lifetime/representation/consumer
fingerprints and rejects consumer-local reinterpretation of storage, lifetime,
unchecked-operation, allocation policy, and diagnostic bridge evidence.

The AUnit suite adds balanced source-shaped rows for:
  * legal initialized allocator evidence;
  * hard No_Allocators restriction evidence;
  * warning-only allocation restriction evidence;
  * runtime accessibility and constraint checks;
  * missing storage/lifetime/profile evidence;
  * allocator subtype, limited, controlled/finalized, null-exclusion, storage
    pool, storage size, representation/freezing, conversion, and accessibility
    blockers;
  * Unchecked_Conversion and Unchecked_Deallocation blockers;
  * generic access substitution and replay blockers;
  * consumer disagreement and stale fingerprint blockers.

This is a real RM gap burn-down pass and does not add a projection/status/render
layer.
