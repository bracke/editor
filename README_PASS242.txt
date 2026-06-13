Editor Phase 579 pass 242

Focus:
- Continue parser gap #1 by expanding statement-awareness metadata to Ada statement labels.

Implemented:
- Added Statement_Label to Editor.Ada_Language_Model.Statement_Kind.
- Added parser-owned recognition of leading Ada labels of the form <<Label>>.
- Added normalization that strips one or more leading labels before classifying the labelled statement.
- Labelled calls and assignments now contribute both label metadata and the underlying statement kind.
- Labels remain metadata only and do not create Outline rows or semantic declaration symbols.
- Extended statement-awareness AUnit coverage.
- Extended phase579_language_validation_check guards.
- Updated README and docs.

Still intentionally not claimed:
- This is not a full statement AST.
- Expression grammar and complete Ada legality remain outside this pass.
