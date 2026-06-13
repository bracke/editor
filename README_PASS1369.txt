Pass1369 - Remaining Gap Remediation Pass 3

Selected concrete Pass1366 remaining-gap inventory item:
Remaining_Stream_Import_Export_Representation_Edge.

This pass remediates the stream operational attribute / import-export / external representation edge that remained after the final readiness inventory. It requires stream Read/Write/Input/Output profile evidence, Convention/Import/Export/External_Name/Link_Name evidence, C-compatible callable profile evidence, access-to-subprogram convention preservation, representation/freezing evidence, private/limited view blockers, runtime address-check preservation, consumer surfacing, balanced regression evidence, and fresh fingerprints to agree before the gap can be promoted to covered.

Added package:
src/core/editor-ada_rm_remaining_gap_remediation_pass1369.ads
src/core/editor-ada_rm_remaining_gap_remediation_pass1369.adb

Added tests:
tests/src/test_ada_rm_remaining_gap_remediation_pass1369.ads
tests/src/test_ada_rm_remaining_gap_remediation_pass1369.adb

The test suite covers legal stream/external agreement, import/export conflicts, runtime address-check preservation, private-view indeterminate evidence, stream profile mismatch, convention mismatch, late stream items after freezing, duplicate operational items, external/link name failures, C profile disagreement, access-to-subprogram convention loss, representation/freezing evidence loss, consumer disagreement, final readiness inventory gates, regression balance, and stale stream/convention fingerprints.

Registered in Core_Suite.
