Pass 261 — assignment target-shape statement awareness

This pass extends parser-owned Ada statement metadata for assignment statements:

- added Statement_Assignment_Selected_Target;
- added Statement_Assignment_Indexed_Target;
- added Statement_Assignment_Slice_Target;
- added parser-side Mark_Assignment_Target_Details;
- ordinary assignments and assignment actions after executable alternatives now retain selected/indexed/slice target-shape metadata;
- no Outline rows, semantic declaration symbols, scopes, or navigation targets are created from assignment target metadata;
- AUnit statement-awareness coverage was expanded;
- language_validation_check now guards the new model/parser markers;
- docs and release checklist were updated.

The parser still remains below a full Ada statement AST or expression/name parser.
