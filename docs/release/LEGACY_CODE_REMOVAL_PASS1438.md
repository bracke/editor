# Case 1438 legacy code removal

Case 1438 removes the obsolete diagnostic recovery render final status scaffold from the active tree.

## Removed files

- `src/core/editor-ada_diagnostic_recovery_render_final_status.ads`
- `src/core/editor-ada_diagnostic_recovery_render_final_status.adb`
- the matching diagnostic recovery render final-status regression package

## Canonical replacement ownership

The historical final-status leaf is superseded by the final release gates:

- case 1428 finite remaining-gap closure
- case 1429 architecture cleanup
- case 1435 diagnostic quality validation
- case 1436 project-scale closure
- case 1437 legacy code removal gate
- case 1438 second legacy code removal gate

## Cleanup rule

Removed diagnostic recovery/render status leaves must not remain production-facing. They may only be represented as release notes or regression evidence. A future restoration requires a real failing corpus case or a concrete RM contradiction; speculative reintroduction is rejected.
