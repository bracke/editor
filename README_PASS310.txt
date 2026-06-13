Editor Phase 579 pass 310

Completeness pass focus:
- Make line-level select alternatives structurally equivalent to compact select alternatives.

Implemented:
- Standalone `then abort` lines are classified as `Node_Select_Alternative`.
- Select-level `else` lines are reclassified under the enclosing select rather than being treated as ordinary if-style `Node_Else_Part` nodes.
- Select-level `terminate` lines are reclassified as structured select alternatives with `Node_Statement_Mode` label `terminate`.
- `Node_Select_Alternative` details now distinguish `or`, `then abort`, `else`, and `terminate` forms.
- Alternative-scope handling now pops a previous select alternative before attaching a line-level terminate alternative.
- Accept-statement `do` detail detection uses the sanitized lowercase line for mixed-case Ada keyword robustness.

Tests/guards:
- Added `Test_Language_Model_Syntax_Tree_Line_Level_Select_Parts_Are_Structured`.
- Updated the existing select-alternative test so select `else` is expected as select-alternative structure.
- Extended `phase579_language_validation_check` guards for line-level select else/terminate reclassification and the new regression test.

Safety:
- Executable statement syntax still does not create Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.
- No Python or shell scripts were added.
