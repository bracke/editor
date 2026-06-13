# Editor Phase 579 pass741 — entry family/index metadata depth

This pass deepens structural token-cursor coverage for Ada entry-family and
entry-index syntax while preserving the editor invariants: analysis remains
snapshot-owned, deterministic, bounded, and parser/model backed; no rendering-side
parsing, compiler invocation, LSP integration, file save/reload, or dirty-state
mutation is introduced.

## Implemented

* Added explicit token-cursor productions for entry-family/index detail:
  * `Production_Entry_Family_Range_Definition`
  * `Production_Entry_Body_Index_Identifier`
  * `Production_Entry_Body_Index_Subtype`
  * `Production_Entry_Barrier_When_Keyword`
  * `Production_Accept_Entry_Index_Expression`
  * `Production_Entry_Call_Selected_Target`
  * `Production_Entry_Call_Selected_Entry_Name`
  * `Production_Entry_Call_Family_Index`
* Entry-family declarations now retain range-definition metadata when the
  family discrete subtype definition is visibly range-shaped.
* Entry bodies using `(for Index in Range)` now retain bounded index identifier
  and index subtype markers in addition to the existing entry-index
  specification marker.
* Entry barriers now retain their `when` keyword boundary separately from the
  barrier condition expression.
* Accept statements using `accept E (Index) (...)` now retain the entry index
  expression separately from the optional parameter profile.
* Selected entry/call forms such as `Obj.E (Index) (Actuals);` now retain
  selected-target, selected-entry-name, and family-index metadata for parser
  consumers.
* Added AUnit regression:
  * `Test_Language_Model_Token_Cursor_Entry_Family_Index_Depth`
* Updated validation guards, parser coverage matrix, Outline documentation,
  semantic-colouring documentation, and release checklist entries.

## Non-goals

This improves structural grammar coverage for Ada entry-family/index syntax and
selected entry-call metadata. It is not compiler-grade tasking legality checking,
entry-family discrete-subtype validation, entry-call profile checking, protected
object resolution, barrier semantic validation, or synchronization analysis.
