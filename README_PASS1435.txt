Pass1435: Phase 579 diagnostic quality validation.

This pass implements nr 5 from the project-scale post-remediation list:
Diagnostic quality pass.

It intentionally does not add new diagnostic infrastructure and does not reopen
finite Remaining_* remediation after pass1428.  Instead it validates that
existing diagnostics are release-useful: correct severity, stable blocker
families, precise source spans, bounded duplicate counts, honest final-readiness
state, consumer agreement, and fresh diagnostic/projection fingerprints.

Added:
- Editor.Ada_Phase579_Diagnostic_Quality_Validation_Pass1435
- Test_Ada_Phase579_Diagnostic_Quality_Validation_Pass1435
- docs/release/DIAGNOSTIC_QUALITY_VALIDATION_PASS1435.md

Rejected states include missing source span, unstable blocker family, wrong
severity, duplicate diagnostic floods, misleading final state, consumer
disagreement, reopened Remaining_* gaps, stale evidence, and missing evidence.
