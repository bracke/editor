Pass1074 — Quick-fix skeleton integration for overload-ranking explanation

This pass extends Editor.Ada_Diagnostic_Quick_Fix_Skeleton with Build_With_Overload_Ranking.  The quick-fix skeleton model can now consume Editor.Ada_Overload_Ranking_Provenance and add a structured, non-mutating "Explain overload ranking" action for accepted semantic diagnostics whose node/span matches overload-ranking provenance.

The new action preserves ranking provenance identity, ranking outcome, candidate/selected/rejected/unknown counts, ranking fingerprint, source span, severity, source family, token kind, syntax node, message payload, and deterministic fingerprints.  Has_Edit remains False for every candidate in this skeleton pass.  Rejected/stale diagnostic indexes still expose no active candidates while preserving rejected-candidate totals.

Regression coverage: Test_Ada_Diagnostic_Quick_Fix_Overload_Ranking_Pass1074.
