Editor Phase 579 - Pass 659
===========================

Focus
-----
This pass improves token-cursor structural grammar coverage for Ada assignment statements by retaining the left-hand target and right-hand expression positions explicitly.

Implementation
--------------
- Added `Production_Assignment_Target`.
- Added `Production_Assignment_Expression`.
- Updated identifier-led assignment parsing to emit the target production after the name suffix path has classified the construct as an assignment.
- Updated assignment parsing to emit the expression production before parsing the right-hand side expression.
- Preserved existing selected-name, indexed-component, slice, and explicit-dereference parsing for assignment targets.
- Preserved nested expression parsing for qualified expressions, case expressions, conditional expressions, and raise expressions with messages in right-hand sides.

Regression coverage
-------------------
- Added AUnit coverage for explicit assignment target productions.
- Added AUnit coverage for explicit assignment expression productions.
- Covered indexed and dereferenced targets.
- Covered nested qualified, case, conditional, and raise expressions in assignment operands.
- Covered recovery across following assignment statements.

Scope note
----------
This is structural grammar coverage only. It is not compiler-grade legality checking for assignability, mode conformance, expected-type resolution, accessibility, target object legality, or runtime assignment semantics.
