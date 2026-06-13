Editor Phase 579 pass 209

Parser-completeness increment:
- Added bounded type-qualifier metadata to Editor.Ada_Language_Model.
- Parser-owned type and generic formal type symbols can now retain limited, tagged, and interface qualifier metadata.
- Outline detail projection can surface limited/tagged/interface metadata.
- Semantic lookup does not learn qualifier keywords as identifiers.
- Added Test_Language_Model_Type_Qualifier_Metadata.
- Extended phase579_language_validation_check and docs/release notes.

No Python or shell scripts were added.
