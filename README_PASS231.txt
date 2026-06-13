Phase 579 pass 231: Ada deferred-constant metadata.

Changes:
- Added Has_Deferred_Constant_Metadata to Editor.Ada_Language_Model.Declaration_Flags.
- Included deferred-constant metadata in deterministic symbol fingerprints.
- Added bounded parser detection for declarations such as Value : constant Element;.
- Kept initialized typed constants and named numbers from being marked as deferred constants.
- Added Outline detail projection for deferred-constant metadata.
- Added Test_Language_Model_Deferred_Constant_Metadata.
- Extended phase579_language_validation_check for the model/parser/test markers.
- Updated README and documentation.

Validation:
- Static archive/marker checks only in this pass.
- No Python or shell scripts were added to the project.
