Editor Phase 579 pass 351

Implemented bounded interpretation of Ada record representation component clauses in the shared language model.

Changes:
- Added Representation_Component_Info to Editor.Ada_Language_Model.
- Added Add_Record_Representation_Component, Representation_Component_Count, and Representation_Component_At.
- Projected parser-owned Node_Representation_Component_Clause nodes into target-record layout metadata.
- Linked layout entries back to record-component symbols when scope ownership resolves cleanly.
- Preserved source spelling for storage unit / bit ranges and parsed simple decimal positions into static numeric fields.
- Added AUnit regression coverage for interpreted record representation layout metadata.
- Updated README, outline docs, semantic-colouring docs, and release-check guard tokens.

Conservative boundary:
- This is not compiler-accurate representation legality checking.
- Arbitrary static expressions are preserved as text rather than evaluated.
- Unknown or unresolved representation targets still degrade without guessing.
