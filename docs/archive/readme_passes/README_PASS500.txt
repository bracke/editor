Pass 500: remaining representation/operational aspect-vs-attribute unification

This pass continues the representation/operational property unification work started in earlier passes.

Implemented:
- Added explicit retained representation/operational kinds for:
  * Default_Storage_Pool
  * Stable_Properties
  * Stable_Properties'Class
  * Relative_Deadline
- Lowered aspect forms and attribute-definition clauses through the same representation metadata path:
  * with Default_Storage_Pool => ...
  * for T'Default_Storage_Pool use ...;
  * with Stable_Properties => ...
  * for T'Stable_Properties'Class use ...;
  * with Relative_Deadline => ...
  * for T'Relative_Deadline use ...;
- Reused common duplicate detection and target-compatibility legality checks.
- Extended storage-pool legality so Default_Storage_Pool shares Storage_Pool access-target and storage-pool-value diagnostics.
- Added required-expression diagnostics for Stable_Properties, Stable_Properties'Class, and Relative_Deadline.
- Added regression coverage in Test_Language_Model_Remaining_Operational_Property_Unification_Pass.
