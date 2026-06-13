Pass1363 — RM Gap Burn-Down Pass 21

Added Editor.Ada_RM_Gap_Burn_Down_Pass1363 and the matching AUnit suite Test_Ada_RM_Gap_Burn_Down_Pass1363.

This pass burns down the project semantic index / multi-buffer cross-unit closure gap.  It enforces one canonical project-wide semantic source snapshot across open dirty buffers, project files, missing/deleted files, duplicate library units, spec/body pairing, child/private-child units, separate subunits, context-clause lookup, cross-buffer invalidation, stale index rejection, and semantic consumer feeds.

The source-shaped model rejects:

* disk text being analyzed in place of an open dirty buffer snapshot,
* scratch/unbacked buffers silently becoming library units,
* missing or deleted files treated as legal empty units,
* duplicate library units accepted as one canonical unit,
* private-child visibility leaks through project index lookup,
* context-clause lookup bypassing the canonical project index,
* consumers resolving cross-unit names independently,
* missing spec/body, child-unit, and separate-subunit index evidence,
* dependent units not invalidated after spec/private/body/generic/context/file edits,
* stale project index, closure, pairing, or consumer feeds,
* needless canonical entity identity churn on unrelated edits,
* file save/reload, dirty-state mutation, rendering-side parsing, and command/keybinding/workspace/render mutation leaks during analysis,
* stale source/AST/buffer/project/index/unit/view/closure/substitution/effect/consumer fingerprints.

The pass also verifies balanced evidence: legal open-buffer precedence, legal project index closure, legal cross-buffer invalidation, missing-file blocker preservation, stable unrelated-edit preservation, and consumer-visible results.

Registered the new test in Core_Suite.
