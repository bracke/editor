Pass 495 - Scheduling representation/operational property unification

Implemented the next representation/operational property unification pass on top of pass 494.

Changes:
- Added explicit retained representation kinds for scheduling-related properties:
  - Priority
  - Interrupt_Priority
  - CPU
  - Dispatching_Domain
- Lowered aspect forms into the same representation metadata stream as attribute-definition clauses:
  - with Priority => ...
  - with Interrupt_Priority => ...
  - with CPU => ...
  - with Dispatching_Domain => ...
- Lowered matching attribute-definition clauses into the same explicit kinds:
  - for T'Priority use ...;
  - for T'Interrupt_Priority use ...;
  - for T'CPU use ...;
  - for T'Dispatching_Domain use ...;
- Reused the shared legality path for duplicate detection and retained value validation.
- Added target compatibility routing for task/protected scheduling properties:
  - Priority and Interrupt_Priority: task/protected targets
  - CPU and Dispatching_Domain: task targets
- Added static natural checking for Priority, Interrupt_Priority, and CPU, with CPU kept on the positive-value path.
- Expanded the representation/operational property unification regression to cover scheduling aspects and matching attribute-definition clauses.
