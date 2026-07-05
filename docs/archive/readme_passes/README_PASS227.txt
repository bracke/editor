pass 227

Parser completeness increment: bounded Ada null-record metadata.

Changes:
- Added Has_Null_Record_Metadata to Editor.Ada_Language_Model.Declaration_Flags.
- Included null-record metadata in deterministic language-model fingerprints.
- Updated Editor.Ada_Declaration_Parser to detect compact null record forms such as:
  * type Empty is null record;
  * type Child is new Root with null record;
- Updated Outline detail projection to show null-record metadata on owning type rows.
- Added Test_Language_Model_Null_Record_Metadata.
- Extended language_validation_check for model/parser/test markers.
- Updated docs and release checklist.

The metadata is bounded: null record syntax does not synthesize record component rows, does not open extra component scopes, and does not learn null/record keywords as identifiers.
