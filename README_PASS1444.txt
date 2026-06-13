Pass1444 - Phase 579 documentation cleanup

Added Editor.Ada_Phase579_Documentation_Cleanup_Pass1444 and matching AUnit coverage.

This pass implements project-scale cleanup item 5: documentation cleanup. It defines the canonical Phase 579 architecture map, keeps release-validation and cleanup-ledger documents as evidence, archives historical pass notes as historical-only material, and rejects documentation that reopens Remaining_* gaps or invents speculative semantic work after the pass1428 finite closure.

The pass prepares Phase 579 for the final dead-code sweep by making the documentation hierarchy explicit:

- canonical architecture map: docs/release/PHASE579_CANONICAL_ARCHITECTURE_MAP_PASS1444.md
- release evidence: project-scale closure and validation reports
- cleanup evidence: legacy inventory, projection-tower removal, Core_Suite pruning, and canonical API consolidation
- historical evidence: individual pass README files that are no longer production API guidance

No semantic Remaining_* backlog is reopened.
