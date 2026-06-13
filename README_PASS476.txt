Pass 476 - Complete attribute-specific representation legality

Implemented a broader attribute-specific representation/operational legality pass.

Highlights:
- Added explicit representation clause kinds for Machine_Radix, Aft, Atomic,
  Volatile, Independent, and Suppress_Initialization instead of leaving these
  under the generic Other representation bucket.
- Added legality diagnostics for:
  * Machine_Radix target class: floating-point type required.
  * Aft target class: fixed-point type required in the bounded metadata model.
  * Small value shape: static numeric expression required.
  * positive-valued representation attributes rejecting retained static zero
    for Alignment, Component_Size, Object_Size, Value_Size, Storage_Size,
    Machine_Radix, and Aft.
  * Atomic/Volatile/Independent target class and static Boolean values.
  * Suppress_Initialization target class and static Boolean values.
  * Storage_Pool value shape: rejects obvious literal/non-pool values.
- Added regression coverage:
  Test_Language_Model_Legality_Attribute_Specific_Representation_Pass

This remains a bounded IDE legality layer; exact RM/static-expression and
full resolver-based conformance still depend on the deeper visibility/type
resolver work.
