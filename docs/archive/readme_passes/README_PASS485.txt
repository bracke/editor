Pass 485 - Aspect vs attribute-definition unification

Implemented a unified semantic path for Ada aspect specifications that are source-equivalent to representation or operational attribute-definition clauses.

Changes:
- Added attribute-definition aspect recognition for representation aspects:
  * Size, Alignment, Bit_Order, Address
  * Storage_Size, Storage_Pool, Component_Size, Object_Size, Value_Size
  * Scalar_Storage_Order, Small, Machine_Radix, Aft
  * Pack, Atomic, Volatile, Independent, Suppress_Initialization
- Added operational stream aspect lowering for Read, Write, Input, and Output.
- Kept interfacing aspects on the same path: Convention, Import, Export, External_Name, Link_Name.
- Boolean representation aspects without explicit values now default to True before legality checking, matching Ada aspect syntax such as `with Pack` and `with Atomic`.
- Aspect association values are normalized from either retained child value nodes or the association label fallback, so attached and standalone syntax-tree shapes feed the same model.
- Lowered attribute-definition aspects into Representation_Clause_Info with the same target symbol, attribute name, item text, static-value metadata, and source range used by `for T'Attribute use ...` clauses.
- Existing duplicate representation diagnostics now work across mixed forms, e.g. an aspect `Alignment => ...` plus `for X'Alignment use ...`.
- Existing target/value legality now applies uniformly to aspect forms, including Component_Size target rules, positive static value rules, link-name string rules, import/export coupling, and stream handler lookup/profile checks.

Regression coverage:
- Added Test_Language_Model_Aspect_Attribute_Definition_Unification_Pass.
- The test verifies representation metadata retention for aspect and clause forms, boolean aspect defaulting, stream aspect lowering, cross-form duplicate diagnostics, and shared legality diagnostics.
