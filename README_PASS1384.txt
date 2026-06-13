Pass1384 - Remaining Gap Remediation Pass 18

Selected remaining gap:
  Remaining_Project_Index_Open_Buffer_Duplicate_Unit_Edge

This pass remediates a concrete project-index and multi-buffer semantic edge where open dirty buffer snapshots, project file index rows, duplicate library-unit candidates, private-child visibility, stale project-index evidence, and semantic consumers must agree on one canonical result.

Added package:
  src/core/editor-ada_rm_remaining_gap_remediation_pass1384.ads
  src/core/editor-ada_rm_remaining_gap_remediation_pass1384.adb

Added tests:
  tests/src/test_ada_rm_remaining_gap_remediation_pass1384.ads
  tests/src/test_ada_rm_remaining_gap_remediation_pass1384.adb

Registered in:
  tests/src/core_suite.adb

The remediation enforces:
  * open buffer precedence over project files,
  * dirty snapshot use for semantic indexing,
  * duplicate library unit rejection,
  * private-child visibility leak rejection,
  * missing unit and missing project file indeterminate states,
  * stale project-index rejection,
  * consumer-surfaced semantic agreement,
  * final readiness gap removal,
  * source, AST, unit, project-index, view, and consumer fingerprint freshness.

This continues the remaining-gap remediation sequence by closing a named Pass1366-style gap instead of adding another broad audit layer.
