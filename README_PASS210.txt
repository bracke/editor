Editor Phase 579 IDE-grade Outline/Semantic Language Model - Pass 210

This pass extends parser completeness with bounded Ada synchronized-interface metadata.

Changes:
- Added Has_Synchronized_Metadata to Editor.Ada_Language_Model.Declaration_Flags.
- Included synchronized metadata in deterministic symbol fingerprints.
- Updated Editor.Ada_Declaration_Parser so type/generic formal declarations such as
  "type T is synchronized interface;" retain synchronized qualifier metadata.
- Updated Outline detail projection to surface synchronized metadata.
- Added Test_Language_Model_Synchronized_Metadata.
- Extended phase579_language_validation_check for model/test guard coverage.
- Updated docs/release checklist/README.

The synchronized keyword remains metadata only: it does not create Outline rows,
open scopes, or become a semantic identifier/resolver target.
