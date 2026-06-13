# Pass 667 - Task and protected body internal grammar

This pass extends the Ada token-cursor grammar with explicit structural
positions for task body and protected body internals.

Changes:

- Added task body productions for:
  - task body name
  - task body declarative part
  - task body statement sequence
  - task body exception part
- Added protected body productions for:
  - protected body name
  - protected body operation part
- Updated task body parsing so the defining task body name and body parts are
  retained before normal bounded body traversal continues.
- Updated protected body parsing so the defining protected body name and
  operation part are retained before nested protected operations are parsed.
- Added AUnit coverage for task bodies with declarations, handled statements,
  and exception parts.
- Added AUnit coverage for protected bodies containing procedure and entry
  bodies, including entry barrier-condition retention.

This improves structural grammar coverage for Ada task and protected body
internals. It is not compiler-grade legality checking for task/protected body
conformance, protected operation legality, barrier typing, elaboration, or
runtime tasking semantics.
