Editor Phase 579 - Pass 661
===========================

Focus: goto/exit target-name structural grammar.

Changes:
- Added `Production_Exit_Loop_Name` to retain the optional loop name in `exit Loop_Name [when ...];` separately from the existing generic exit-target marker.
- Added `Production_Goto_Label_Name` to retain the target label name in `goto Label_Name;` separately from the existing generic goto-target marker.
- Preserved existing `Production_Exit_Target`, `Production_Exit_When_Condition`, and `Production_Goto_Target` emissions for current consumers.
- Extended AUnit coverage for named exits, exit `when` conditions, goto targets, following explicit labels, and recovery into the subsequent statement.
- Updated README and release checklist notes.

Scope:
This improves structural grammar coverage for Ada goto and exit target names. It is not compiler-grade legality checking for label resolution, loop-name matching, duplicate labels, reachability, or control-flow legality.
