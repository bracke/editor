Editor pass 274

Implemented parser-owned compact elsif-action statement awareness.

Changes:
- Added Statement_Elsif_Action to Editor.Ada_Language_Model.Statement_Kind.
- Added Mark_Compact_Elsif_Action_Details to Editor.Ada_Declaration_Parser.
- Parser now retains visible same-line if/elsif action shape, for example:
    if Ready then null; elsif Retry then Worker.Deliver (Name => Item); end if;
- Embedded elsif actions retain simple action metadata for calls, named associations, assignments, return expressions, raise forms, and code statements where visible.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from elsif action syntax.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check.
- Updated README and Outline/Semantic/Release documentation.

This continues closing parser gap nr 1 while staying bounded metadata-level rather than a full Ada statement/name/expression AST.
