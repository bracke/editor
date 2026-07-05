Editor Pass 251
=========================

Focus
-----
Continue closing parser gap nr 1 with a bounded statement-awareness improvement for stacked Ada statement labels.

Implemented
-----------
- Added parser-side Leading_Statement_Label_Count.
- Added parser-side Mark_Leading_Statement_Labels.
- Multiple leading statement labels such as:

    <<Retry>> <<Again>> Work;

  now contribute one Statement_Label metadata count per label.
- Label-only lines contribute label metadata without creating fake statements.
- Stacked labels are still stripped before the underlying statement is classified, so the example above also remains a call statement.
- Label identifiers are not learned as declaration symbols.
- No Outline rows, semantic declaration symbols, scopes, or navigation targets are created from statement labels.
- Added AUnit coverage for stacked same-line labels and label-only lines.
- Extended language_validation_check with explicit stacked-label guards.
- Updated README, outline docs, semantic-colouring docs, and release checklist.

Still intentionally not claimed
-------------------------------
- No full Ada statement AST.
- No expression AST.
- No compiler-grade statement legality checking.
