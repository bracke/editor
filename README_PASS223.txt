Phase 579 pass 223

This pass adds bounded Ada class-wide subtype-mark metadata to the parser-owned language model.

Changes:
- Added Has_Class_Wide_Metadata to Declaration_Flags.
- Included class-wide metadata in deterministic symbol fingerprints.
- Updated the declaration parser to detect T'Class-style subtype marks on owning declarations.
- Exposed class-wide detail in Outline metadata.
- Added Test_Language_Model_Class_Wide_Metadata.
- Extended phase579_language_validation_check guards.

Class-wide metadata remains non-declarative: it does not create Outline rows, semantic symbols, scopes, or compiler-grade tagged-type resolution.
