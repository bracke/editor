Pass1071 implements overload ranking metadata.

Added package:
- Editor.Ada_Overload_Ranking

The package consumes the snapshot-owned expression type model and overload ambiguity cause metadata, then classifies call/operator/universal-numeric evidence as exact match, implicit-conversion-ranked, universal-numeric tie-break, ambiguous after ranking, no ranked candidate, or unknown.

Expression diagnostics now accept overload ranking metadata through Build_With_Overload_Ranking and Build_With_All_Semantic_Causes_And_Ranking. Successful ranking states remain provenance metadata; rejected, ambiguous, or unknown ranking states are projected into deterministic expression diagnostics.

Regression:
- Test_Ada_Overload_Ranking_Pass1071

Invariants preserved:
- no rendering-side parsing
- no file saves or reloads during analysis
- no dirty-state mutation
- no command, keybinding, workspace, or render mutation leaks
- deterministic snapshot-owned metadata and fingerprints
