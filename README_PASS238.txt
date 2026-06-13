Editor Phase 579 pass 238

This pass adds bounded Ada generic-instantiation actual-part metadata.

Highlights:
- Added Has_Generic_Actual_Part_Metadata to Editor.Ada_Language_Model.Declaration_Flags.
- Included the new flag in deterministic language-model fingerprints.
- Updated Editor.Ada_Declaration_Parser so package/subprogram/formal-package instantiations with actual lists retain generic-actuals metadata.
- Kept derived type constraints distinct from generic actual lists.
- Updated Outline detail projection to show generic-actuals.
- Added Test_Language_Model_Generic_Actual_Part_Metadata.
- Extended the Phase 579 validation guard and docs.
