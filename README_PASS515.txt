Pass 515 - Representation pragma value unification

This pass extends the representation/operational property unification work by
closing a pragma-side drift that remained after the aspect and
attribute-definition clause resolver was centralized.

Implemented:
- Lower scheduler/concurrency representation pragmas into the same retained
  representation item stream as equivalent aspect and attribute-definition
  forms:
  * Priority
  * Interrupt_Priority
  * CPU
  * Dispatching_Domain
  * Relative_Deadline
  * Max_Entry_Queue_Length
- Preserve pragma argument values for value-carrying representation pragmas
  instead of treating all lowered pragmas as bare Boolean properties.
- Parse and retain static natural values for lowered representation pragmas so
  the shared static-value legality diagnostics apply equally to pragma,
  aspect, and attribute-definition clause source forms.
- Keep Attach_Handler, Optimize, Suppress/Unsuppress, and policy-style pragmas
  on the same value extraction path while preserving their existing argument
  shapes.
- Fixed a parser typo in positional enumeration representation mapping that
  had left a duplicated else branch in the generated pass chain.

Result:
- Value-bearing pragmas now participate in the same duplicate, target, and
  static-value legality checks as their aspect and attribute-definition clause
  counterparts.
