Editor Phase 579 Pass 235

This pass adds bounded Ada access-protected declaration metadata.

Changes:
- Added Has_Access_Protected_Metadata to Editor.Ada_Language_Model.Declaration_Flags.
- Included access-protected metadata in deterministic symbol fingerprints.
- Updated Editor.Ada_Declaration_Parser to detect access protected procedure/function forms.
- Updated Outline detail projection to show access-protected.
- Added Test_Language_Model_Access_Protected_Metadata.
- Extended phase579_language_validation_check coverage.
- Updated docs, release checklist, and README.

No Python or shell scripts were added.
