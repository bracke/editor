# Phase 579 Pass1437 Legacy Code Removal

Pass1437 removes one obsolete scaffold from the active source and test tree instead of merely quarantining it.

Removed files:

- `src/core/editor-ada_repair_gated_diagnostic_provenance.ads`
- `src/core/editor-ada_repair_gated_diagnostic_provenance.adb`
- `tests/src/test_ada_repair_gated_diagnostic_provenance_pass1151.ads`
- `tests/src/test_ada_repair_gated_diagnostic_provenance_pass1151.adb`

The corresponding `Core_Suite` `with` clause and `Add_Test` registration were also removed.

Reason: the removed package was a historical repair-gated diagnostic provenance scaffold. It is no longer a production semantic surface after the finite Remaining_* closure, architecture cleanup, release-readiness validation, project-scale validation, and final project-scale closure passes.

Replacement owner: the canonical Phase 579 final validation and cleanup surfaces.

Future rule: do not add compatibility aliases or replacement wrappers for removed legacy packages. A removed legacy package may only be restored if a concrete source-shaped corpus failure or RM contradiction demonstrates that no canonical production surface can express the required behavior.
