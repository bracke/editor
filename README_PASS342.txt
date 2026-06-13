Editor phase 579 pass342

Completeness pass focus: token-cursor Ada expression grammar.

Changes:
- Added token-cursor grammar productions for allocator expressions.
- Added token-cursor grammar productions for raise expressions.
- Added membership choice-list and membership-choice productions for `in` and `not in` relations.
- Added short-circuit operation productions for `and then` and `or else`.
- Added unary-expression production events for `abs`, `not`, unary `+`, and unary `-`.
- Added delta-aggregate production events for `(... with delta ...)` forms.
- Added reduction-expression production events for reduction attributes such as `'Reduce`.
- Added AUnit coverage and validation guards for the expanded expression grammar.

No Python or shell scripts are part of the project.
