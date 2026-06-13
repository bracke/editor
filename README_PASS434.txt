Pass 434 — Record component-definition grammar

Implemented a focused Ada parser-completeness pass for record component declarations.

Changes:
- Added Production_Component_Definition to Editor.Ada_Token_Cursor.
- Added structural parsing for record component definitions instead of opaque semicolon skipping.
- Component declarations now retain defining-name lists, colon, aliased component markers, subtype/access definitions, not-null access forms, and default expressions.
- Added AUnit regression coverage for component definitions such as:
  Left, Right : aliased not null access Node := Default_Node;
- Updated validation guards, release guard comments, README/docs, and release checklist.

Limits:
- This is grammar retention only.
- It does not perform compiler-grade component legality, representation legality, access-level validation, default-expression type checking, or full semantic legality checks.
