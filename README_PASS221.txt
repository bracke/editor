Phase 579 pass 221

This pass adds bounded Ada box (`<>`) declaration metadata to the parser-owned language model.

Implemented:
- Added `Has_Box_Metadata` to `Editor.Ada_Language_Model.Declaration_Flags`.
- Included box metadata in deterministic symbol fingerprints.
- Updated `Editor.Ada_Declaration_Parser` to mark declarations containing sanitized `<>` syntax.
- Updated Outline detail projection to show `box` metadata.
- Added `Test_Language_Model_Box_Metadata` covering generic formal scalar boxes, boxed generic formal object defaults, generic formal package actual boxes, and unconstrained array bounds.
- Extended `phase579_language_validation_check` for model/parser/test markers.
- Updated README and language documentation.

Box syntax remains metadata only: it does not create Outline rows, open scopes, or add generic actual expressions/bounds to semantic lookup.
