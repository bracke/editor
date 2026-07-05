Pass 523 - value-only pragma scope binding

Implemented another convergence pass for representation/operational pragma lowering.

Changes:
- Added current-scope binding for value-only pragmas that do not name an entity argument:
  * Priority
  * Interrupt_Priority
  * CPU
  * Dispatching_Domain
  * Relative_Deadline
  * Max_Entry_Queue_Length
  * SPARK_Mode
  * Assertion_Policy
  * Check_Policy
  * Debug_Policy
  * Restrictions
  * Restriction_Warnings
  * Profile
- These pragmas now attach representation/operational metadata to the current retained scope instead of trying to resolve their first value/policy argument as a declaration name.
- Preserved SPARK_Mode's explicit value (for example On) instead of lowering it as a bare True property.
- Kept the lowered metadata on the shared Representation_Kind_For resolver path so aspects, attribute-definition clauses, and pragma forms reuse the same duplicate/target/value legality checks.
- Added regression coverage for current-scope SPARK_Mode and Assertion_Policy pragma retention.
