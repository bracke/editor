# Pass 650 - Block-statement declarative/handled/exception part grammar

This pass improves structural token-cursor coverage for Ada block statements.

Changes:

- Added `Production_Block_Declarative_Part`.
- Added `Production_Block_Statement_Sequence`.
- Added `Production_Block_Exception_Part`.
- Split statement-level handling of `declare`, `begin`, and `exception` so nested block declarations, handled statements, and exception parts are visible as separate structural positions.
- Preserved existing generic `Production_Statement_Sequence` markers for current consumers.
- Added AUnit regression coverage for labelled nested blocks with local declarations, handled statements, exception handlers, raise statements with messages, and recovery into following assignments.

This improves structural grammar coverage for Ada block statements. It is not compiler-grade legality checking for block declarative legality, exception-choice legality, handler reachability, or control-flow semantics.
