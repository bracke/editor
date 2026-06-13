Phase 579 pass 225

Implemented a bounded Ada parser/model coverage increment for named-number declarations.

Changes:
- Added Has_Named_Number_Metadata to Editor.Ada_Language_Model.Declaration_Flags.
- Included named-number metadata in deterministic symbol fingerprints.
- Updated Editor.Ada_Declaration_Parser to detect declarations of the form Name : constant := Expr;.
- Kept typed constants distinct from named numbers.
- Updated Outline detail projection so affected constants can show named-number metadata.
- Added Test_Language_Model_Named_Number_Metadata.
- Extended phase579_language_validation_check for the new model/parser/test markers.
- Updated docs and release checklist.

Static validation:
- Archive integrity checked.
- No Python or shell scripts added.
