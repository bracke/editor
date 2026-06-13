Editor Phase 579 - Pass 649
===========================

Focus
-----
Improve structural token-cursor grammar coverage for Ada case statements by retaining the case selector and alternative statement-sequence positions explicitly.

Implementation
--------------
- Added `Production_Case_Statement_Selector`.
- Added `Production_Case_Alternative_Statement_Sequence`.
- Updated statement-level `case` parsing so the selector expression is marked before it is parsed.
- Updated `when ... =>` alternative parsing so the statement sequence position after `=>` is explicit while preserving the existing generic statement-sequence marker.

Regression coverage
-------------------
Extended AUnit token-cursor coverage with a case statement containing:
- an arithmetic selector expression,
- choice lists and range choices,
- nested conditional-expression and raise-statement constructs in alternatives,
- recovery into a following assignment statement.

Boundary
--------
This improves structural grammar coverage for Ada case-statement selector and alternative statement positions. It is not compiler-grade legality checking for selector type, choice coverage, choice overlap, or statement legality.
