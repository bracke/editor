Pass1340 - Semantic consumer enforcement audit

This pass starts the semantic-consumer enforcement stage after the RM coverage
matrix and remediation audits.  It adds
Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340 and verifies that
completed Ada semantic legality results are surfaced through real editor
semantic consumers without each consumer inventing its own interpretation of
names, types, views, profiles, units, substitutions, or blocker families.

The pass audits these consumers as separate enforcement rows:

* diagnostics;
* semantic colouring;
* outline/symbol model;
* semantic navigation/go-to-definition style lookup;
* hover and semantic detail payloads;
* the external build diagnostic bridge.

A consumer row is accepted only when it is source-shaped, uses the canonical
semantic model, consumes the semantic result, preserves stable source spans,
keeps runtime-check evidence, and has fresh source/AST/type/profile/
substitution/effect/consumer fingerprints.  Diagnostics and partial/blocked RM
families must carry stable semantic blocker-family identity.  Semantic colouring
must not independently re-resolve names or types.  Outline and navigation must
use canonical declaration, completion, entity, renaming, generic substitution,
and cross-unit evidence.  Hover/detail payloads must come from canonical
evidence rather than slice-local evidence.  The build diagnostic bridge must
remain distinct from internal Ada semantic diagnostics while sharing stable
source spans.

The pass rejects hidden covered results, silently hidden partial/blocked states,
noncanonical consumer models, stale fingerprints, missing source-shaped
evidence, missing consumer rows, and duplicated consumer rows.

Added AUnit coverage:

* all six semantic consumers using canonical evidence;
* diagnostics without stable blocker-family evidence;
* semantic colouring that reinterprets names/types;
* outline/navigation identity mismatches;
* hover/build bridge slice-local or conflated evidence;
* covered/blocked semantic results that cannot be surfaced;
* stale consumer/evidence fingerprints;
* missing consumer rows.
