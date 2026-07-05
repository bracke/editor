Pass1442:  canonical API consolidation.

This pass implements project-scale cleanup item 3.  It names the final
production-facing API surfaces and separates them from regression
evidence, cleanup gates, quarantined legacy scaffolds, and removed legacy
surfaces.

The pass keeps the pass1428 Remaining_* closure intact.  It rejects command
aliases, compatibility spellings, legacy diagnostic projection surfaces
returning as production APIs, references to already removed legacy surfaces,
missing tests/docs, stale API fingerprints, and reopened remaining-gap work.

The result is a deterministic canonical API ledger that unblocks later
Core_Suite pruning and documentation-map cleanup without reintroducing the
projection/provenance scaffolding removed in passes1437 through 1441.
