Editor Phase 579 - Pass 658
===========================

Focus: abort-statement target-list grammar.

Implemented changes
-------------------

- Added token-cursor productions for abort-statement target-list internals:
  - Production_Abort_Target_List
  - Production_Abort_Target_Name
- Updated abort-statement parsing so `abort A, B.C (I), D.all;` retains:
  - the abort-statement node
  - the overall target-list position
  - each individual abort target
  - each individual task-name position
- Preserved existing selected-name, indexed-component, and explicit-dereference suffix parsing through the existing primary/name parser path.
- Extended AUnit coverage for abort statements in the general statement grammar completeness test and the dedicated abort-statement grammar regression test.
- Updated README.md and docs/release/RELEASE_CHECKLIST.md with the pass notes.

Scope
-----

This improves structural grammar coverage for Ada abort-statement target lists. It is not compiler-grade legality checking for task-name resolution, tasking-context legality, abortability, accessibility, or runtime task semantics.
