# Phase 579 Legacy Scaffold Inventory — Pass1440

Pass1440 closes the first post-release-cleanup item: complete the legacy scaffold inventory before continuing destructive removal.

## Classification rule

No additional semantic Remaining_* work is opened by this pass.  Historical packages must be classified into one of four buckets:

* production: canonical production-facing semantic or diagnostic surface;
* regression evidence: retained because it proves a closed semantic/release gate;
* quarantine: legacy scaffold that must be isolated and checked before deletion;
* remove: finite destructive-removal candidate for later cleanup passes.

## Initial finite ledger

Production:

* Editor.Ada_Language_Model
* Editor.Ada_Semantic_Diagnostic_Feed

Regression evidence:

* Editor.Ada_RM_Remaining_Gap_Remediation_Pass1428
* Editor.Ada_Phase579_Project_Scale_Closure_Pass1436

Quarantine before deletion:

* Editor.Ada_Diagnostic_Recovery_Status
* Editor.Ada_Diagnostic_Recovery_Render_Projection

Removal candidates:

* Editor.Ada_Diagnostic_Command_Palette_Projection
* Editor.Ada_Diagnostic_Keybinding_Hint_Projection
* Editor.Ada_Repair_Gated_Diagnostic_Integration
* Editor.Ada_Final_Semantic_Remediation_Worklist_Legality
* Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index

## Rejection gates

The pass rejects:

* production-facing legacy scaffolds without quarantine/remove ownership;
* references to already removed scaffolds;
* command aliases or compatibility spellings introduced by cleanup;
* any reopened Remaining_* gap after pass1428;
* stale inventory fingerprints;
* missing owners or unclassified surfaces.

This gives the next cleanup work a finite target list and prevents legacy cleanup from becoming another endless pass loop.
