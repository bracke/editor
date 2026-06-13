Pass1413 - Remaining Imported Subprogram Preelaborate Elaboration Edge

Added:
- Editor.Ada_RM_Remaining_Gap_Remediation_Pass1413
- Test_Ada_RM_Remaining_Gap_Remediation_Pass1413

Selected concrete remaining gap:
- Remaining_Imported_Subprogram_Preelaborate_Elaboration_Edge

This pass closes a concrete RM remediation edge for imported subprogram declarations and calls in preelaborated or elaboration-sensitive contexts by treating import/profile evidence, convention and external-name evidence, preelaborable-initialization restrictions, elaboration effects, runtime elaboration checks, warnings, indeterminate evidence states, and semantic consumers as one canonical result.

Coverage added:
- legal imported subprogram declaration in a preelaborated context
- illegal imported subprogram body-completion rejection
- illegal preelaborate elaboration-call rejection
- illegal missing import convention rejection
- illegal external-name/link-name conflict rejection
- illegal preelaborable-initialization violation rejection
- runtime elaboration-check preservation
- warning-only preservation
- private/full-view indeterminate blocker preservation
- missing import evidence blocker preservation
- missing elaboration evidence blocker preservation
- stale elaboration evidence rejection
- semantic consumer agreement for the import/elaboration result
- final readiness gap removal evidence
- source, AST, type, profile, import, elaboration, effect, and consumer fingerprint freshness gates
