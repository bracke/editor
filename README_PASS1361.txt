Pass1361 — RM Gap Burn-Down Pass 19

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1361 and its AUnit suite Test_Ada_RM_Gap_Burn_Down_Pass1361.

Purpose
-------
Pass1361 burns down the incremental snapshot / semantic invalidation gap for the live editor Ada semantic model.  Pass1360 made partial and recovered source precise for one snapshot.  Pass1361 verifies that semantic results are preserved, invalidated, or recomputed correctly across subsequent snapshots while preserving the editor invariants.

Rules covered
-------------
The pass models source-shaped incremental semantic rows carrying:

* buffer identity
* source revision
* lifecycle generation
* request token
* recovery generation
* source/AST/type/profile/unit/substitution/effect/policy/recovery/consumer fingerprints
* changed dependency kind
* semantic result kind
* consumer path
* remediation and RM coverage state

It enforces that:

* unrelated whitespace/comment edits preserve stable canonical entity identity;
* AST shape edits invalidate dependent AST/type/profile/name results;
* declaration edits invalidate scope/name/visibility results;
* type edits invalidate aggregate/assignment/call/conversion results;
* generic formal edits invalidate substitution and generic body replay;
* context-clause edits invalidate cross-unit visibility and elaboration results;
* representation edits invalidate freezing/layout/interfacing results;
* contract/flow edits invalidate diagnostic and hover/detail consumers;
* recovery-shape edits invalidate recovered-source semantic rows;
* consumers reject stale rows instead of recomputing names or types independently;
* diagnostics do not survive old request tokens;
* outline/navigation/hover/detail rows do not use stale declaration/type/profile identity;
* runtime-check evidence can be preserved when the relevant dependency remains valid;
* stale snapshot/fingerprint evidence is classified as indeterminate;
* semantic analysis does not save/reload files, mutate dirty state, parse on the render path, leak command/keybinding/workspace/render mutations, or perform unbounded recomputation.

Tests added
-----------
The AUnit suite covers:

1. balanced incremental invalidation closure with preserved, invalidated, recomputed, and runtime-check rows;
2. dependency edits that must invalidate or recompute dependent results;
3. rejection of stale live-editor rows for old request tokens, cross-unit closure, generic body replay, representation/freezing, and recovery;
4. stable preservation without canonical entity identity churn;
5. consumer and editor-invariant bypass rejection;
6. snapshot and fingerprint staleness classified as indeterminate.

Files added
-----------

* src/core/editor-ada_rm_gap_burn_down_pass1361.ads
* src/core/editor-ada_rm_gap_burn_down_pass1361.adb
* tests/src/test_ada_rm_gap_burn_down_pass1361.ads
* tests/src/test_ada_rm_gap_burn_down_pass1361.adb

Core_Suite registration was updated to include Test_Ada_RM_Gap_Burn_Down_Pass1361.
