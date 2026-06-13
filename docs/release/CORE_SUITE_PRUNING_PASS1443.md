# Phase 579 Core_Suite pruning - pass1443

Pass1443 implements project-scale cleanup item 4: Core_Suite pruning.

## Purpose

The suite should keep production and meaningful regression coverage active while removing obsolete legacy-scaffold tests from the active execution surface.  Historical code may remain as quarantined reference evidence, but it must not keep obsolete architecture active through Core_Suite registration.

## Pruned from Core_Suite

- `Test_Ada_Repair_Gated_Diagnostic_Integration_Pass1150`
- `Test_Ada_Final_Semantic_Remediation_Worklist_Legality_Pass1204`
- `Test_Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index_Pass1294`

These registrations represented superseded repair-gate, remediation-worklist, and stabilized search-index scaffolding.  They are no longer part of the canonical Phase 579 production or validation surface after the pass1428 semantic closure and the pass1442 canonical API consolidation.

## Kept active

- canonical semantic closure tests;
- real Ada corpus validation tests;
- cleanup gates, including inventory, legacy removal, canonical API consolidation, and this pruning pass.

## Gates

The pass rejects:

- stale legacy registrations;
- canonical tests silently missing from Core_Suite;
- removed test-file families that still appear active;
- unregistered evidence without justification;
- command aliases or compatibility spellings;
- reopened `Remaining_*` gaps after pass1428;
- stale suite, test, or inventory fingerprints.
