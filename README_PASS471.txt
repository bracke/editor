Pass 471 - Interfacing representation/operational attribute legality

Focus:
- Extend the bounded Ada legality layer beyond storage-specific representation attributes.

Implemented:
- Added legality diagnostics for interfacing attribute target/value checks:
  * Legality_Interfacing_Attribute_Target_Incompatible
  * Legality_Interfacing_Link_Name_Target_Incompatible
  * Legality_Interfacing_String_Value_Required
- Added target-class checking for retained attribute definition clauses using:
  * Convention
  * Import
  * Export
  * External_Name
  * Link_Name
- Convention now requires a retained type/object/subprogram/task/protected-like target.
- Import and Export now require a retained object/subprogram-like target.
- External_Name and Link_Name now require a retained object/subprogram-like target.
- External_Name and Link_Name now require a static string literal value in the bounded model.
- Added regression coverage:
  * Test_Language_Model_Legality_Interfacing_Attribute_Target_Pass

Notes:
- This remains a model-backed legality pass. Full interfacing legality still depends on deeper entity-class resolution, convention identifiers, import/export aspect interactions, and profile/type conformance.
