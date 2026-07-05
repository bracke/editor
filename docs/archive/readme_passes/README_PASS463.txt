Pass 463 - block-label and named-exit legality

Focus
- Extend the bounded Ada legality layer from labels/goto/visibility/renaming into named loop/block exits.

Changes
- Added Legality_Duplicate_Block_Label.
- Added Legality_Exit_Missing_Target.
- Extended the executable-binding legality pass so prefix labels retained as Binding_Block_Label are checked for same-scope duplicates.
- Extended named exit checking so `exit Missing_Loop;` is diagnosed when no retained same-scope loop/block label exists.
- Preserved pass 461 `<<label>>` and goto checks separately: goto targets still resolve only to statement labels, while named exits resolve to retained block/loop labels.

Tests
- Added Test_Language_Model_Legality_Block_Label_Exit_Pass.

Notes
- This remains a bounded IDE legality check. Full Ada transfer-control accessibility and region legality are still deeper control-flow analysis work.
