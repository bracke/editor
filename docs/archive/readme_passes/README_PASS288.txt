Pass 288 — parser-owned attribute-reference call statement awareness

This pass continues parser gap nr 1 by preserving another Ada statement name
shape without creating Outline rows or semantic declaration symbols.

Implemented:
- Added Statement_Call_Attribute_Name to Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side Call_Has_Attribute_Name and Alternative_Call_Has_Attribute_Name.
- Parser now recognizes attribute-reference procedure-call statement shapes such as:
    Buffer_Type'Write (Stream, Buffer);
    Buffer_Type'Read (Stream, Buffer);
- Attribute-reference calls remain ordinary Statement_Call metadata and retain
  call-argument metadata where visible.
- Qualified-expression code statements such as Instruction'(Opcode => 16#90#);
  remain Statement_Code and are not flattened into attribute-call metadata.
- Attribute names are not learned as declarations, scopes, semantic symbols,
  Outline rows, or navigation targets.

Updated:
- AUnit statement-awareness coverage.
- language_validation_check guards.
- README.md.
- docs/outline.md.
- docs/syntax_colouring.md.
- docs/release/RELEASE_CHECKLIST.md.

This remains bounded statement-awareness metadata, not a full Ada statement/name/
expression AST.
