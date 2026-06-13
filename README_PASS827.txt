Pass827 - Discriminant part delimiter and recovery depth

Pass827 deepens Ada discriminant-part grammar metadata. Shared discriminant-part parsing now records opening and closing delimiters, semicolon separators between discriminant specifications, and a bounded missing-close recovery boundary for malformed or in-progress discriminant parts.

Highlights:
- Added token-cursor productions for discriminant-part open/close delimiters, discriminant-specification separators, and missing-close recovery.
- Preserved unknown discriminant part handling for `(<>)` while adding delimiter metadata around it.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Discriminant_Part_Delimiters_Pass827`.
- Updated validation guards, parser coverage documentation, syntax-colouring notes, and the release checklist.

This improves structural grammar coverage for Ada discriminant parts. It is not compiler-grade discriminant legality checking, discriminant-conformance validation, subtype legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
