Editor Phase 579 - Pass 660
===========================

Focus: label-name structural grammar.

Changes:
- Added `Production_Label_Name` to the token-cursor production set.
- Explicit label statements such as `<<Again>>` now retain the label name separately from the label delimiter production.
- Statement identifiers before compound statements now retain their identifier as an explicit label-name position.
- Preserved existing `Production_Label` and `Production_Labeled_Statement` production emission for current consumers.
- Extended AUnit coverage for label-name retention in both explicit labels and statement identifiers.
- Updated README and release checklist notes.

Scope:
This improves structural grammar coverage for Ada label names and statement identifiers. It is not compiler-grade legality checking for label/goto resolution, duplicate labels, statement-name matching, or control-flow legality.
