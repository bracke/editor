# Editor Phase 579 - Pass 668

Pass 668 extends the Ada token-cursor grammar for task and protected
specification internals.

Changes:

- Added dedicated productions for task definition public/private parts:
  - `Production_Task_Definition_Public_Part`
  - `Production_Task_Definition_Private_Part`
- Added dedicated productions for protected definition public/private parts:
  - `Production_Protected_Definition_Public_Part`
  - `Production_Protected_Definition_Private_Part`
- Preserved existing task/protected declaration, type declaration, definition,
  discriminant-part, entry declaration, entry profile, and private-part
  productions for current consumers.
- Added AUnit regression coverage for task and protected type definitions with
  discriminants, public entries/subprograms, private sections, and recovery into
  following declarations.

This improves structural grammar coverage for Ada task and protected definition
parts. It is not compiler-grade legality checking for task/protected
specification conformance, private-item legality, protected-operation legality,
entry visibility, or tasking semantics.
