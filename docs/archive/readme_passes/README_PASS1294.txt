Pass1294 implements Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index.

This pass adds a blocker-family-aware semantic search index over Pass1293 stabilized remaining RM edge closure diagnostic provenance.  The index preserves provenance status, diagnostic status/family, stabilized closure family, remaining RM edge kind, remaining-edge local blocker family, syntax node, source span, source/substitution/edge/closure/diagnostic/provenance fingerprints, emitted/withheld/recheck/downstream-blocking state, and full chain linkage.

The pass is intentionally semantic lookup infrastructure for downstream compiler-grade consumers.  It does not add UI, command, palette, rendering, workspace, lifecycle, or compatibility behavior.  It keeps accepted stabilized remaining-edge closure evidence searchable as current non-diagnostic semantic evidence and keeps blocker rows searchable by their original family.

Added test coverage: Test_Ada_Remaining_RM_Edge_Stabilized_Closure_Search_Index_Pass1294.
