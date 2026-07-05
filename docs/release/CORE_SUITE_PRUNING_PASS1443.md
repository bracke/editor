# suite pruning - case 1443

Case 1443 implements project-scale cleanup item 4: suite pruning.

## Purpose

The suite should keep production and meaningful regression coverage active while removing obsolete legacy-scaffold tests from the active execution surface.  Historical code may remain as quarantined reference evidence, but it must not keep obsolete architecture active through suite registration.

## Pruned from active suite

- `Test_Ada_Repair_Gated_Diagnostic_Integration_Case 1150`
- `Test_Ada_Final_Semantic_Remediation_Worklist_Legality_Case 1204`
- `Test_Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index_Case 1294`

These registrations represented superseded repair-gate, remediation-worklist, and stabilized search-index scaffolding.  They are no longer part of the canonical production or validation surface after the case 1428 semantic closure and the case 1442 canonical API consolidation.

## Kept active

- canonical semantic closure tests;
- real Ada corpus validation tests;
- cleanup gates, including inventory, legacy removal, canonical API consolidation, and this pruning pass.

## Gates

The pass rejects:

- stale legacy registrations;
- canonical tests silently missing from active suite;
- removed test-file families that still appear active;
- unregistered evidence without justification;
- command aliases or compatibility spellings;
- reopened `Remaining_*` gaps after case 1428;
- stale suite, test, or inventory fingerprints.
