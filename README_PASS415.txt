Editor phase579 IDE-grade outline/semantic language model pass415

Focus
- Extend token-cursor Ada grammar coverage for null exclusions on access definitions and anonymous access subtypes.

Implemented
- Added Production_Null_Exclusion to Editor.Ada_Token_Cursor.
- Added Parse_Null_Exclusion and integrated it into access type definitions and subtype indications.
- Recognized type definitions such as `type Ptr is not null access all Integer;`.
- Recognized access-to-subprogram forms such as `not null access protected procedure (...)`.
- Recognized object/formal subtype forms such as `Current : not null access constant Integer;` and `Hook : not null access procedure`.
- Added AUnit regression coverage in Test_Language_Model_Token_Cursor_Null_Exclusion_Access_Grammar_Completeness.
- Updated validation/release guards and documentation.

Limits
- This is grammar retention, not compiler-grade nullability, accessibility, subtype conformance, access-to-subprogram profile conformance, or overload legality checking.
