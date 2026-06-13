Pass1446 closes the Phase 579 legacy-cleanup campaign.

Added:
- Editor.Ada_Phase579_Legacy_Cleanup_Closure_Pass1446
- Test_Ada_Phase579_Legacy_Cleanup_Closure_Pass1446
- docs/release/LEGACY_CLEANUP_CLOSURE_PASS1446.md

The pass records a finite seven-item cleanup ledger:
1. legacy scaffold inventory
2. legacy projection tower removal
3. canonical API consolidation
4. Core_Suite pruning
5. documentation cleanup
6. final dead-code sweep
7. cleanup closure

It rejects reopened Remaining_* semantic gaps, speculative cleanup work not backed by inventory evidence, references to removed legacy surfaces, missing tests/docs, missing Core_Suite registration, unclassified legacy surfaces, and stale cleanup fingerprints.
