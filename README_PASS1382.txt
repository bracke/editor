Pass1382 - Remaining Gap Remediation Pass 16

Adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1382.

Selected concrete remaining gap:

  Remaining_Dispatching_Null_Abstract_Effect_Edge

This pass remediates a tagged/interface dispatching edge where abstract
primitive completion, null procedure profile conformance, class-wide
conversion legality, dispatching ambiguity, runtime tag checks, and
contract/effect joins must share one canonical semantic result.

The remediation package models source-shaped rows with Pass1366 inventory
ownership, RM coverage promotion, balanced regression evidence, semantic
consumer surfacing, and freshness checks for source, AST, type, profile,
effect, and consumer fingerprints.

Added AUnit coverage:

  Test_Ada_RM_Remaining_Gap_Remediation_Pass1382

The tests cover:

* legal interface dispatching agreement
* illegal abstract primitive left unimplemented
* illegal null procedure profile mismatch
* illegal ambiguous dispatching candidate
* illegal class-wide conversion mismatch
* illegal dispatching effect-join mismatch
* legal-with-runtime-check tag checks
* indeterminate missing interface evidence
* indeterminate private/full-view and stale-dispatch evidence
* inventory, corpus-balance, consumer, final-gate, and fingerprint gates

Registered the new suite in Core_Suite.
