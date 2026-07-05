Pass830 - Qualified-expression operand delimiter and recovery depth

Pass830 improves structural grammar coverage for Ada qualified expressions by
recording operand opening delimiters, closing delimiters, and bounded
missing-close recovery metadata for qualified-expression operands parsed after
Subtype_Mark'(...). The same metadata is emitted for allocator qualified
expressions such as new T'(...), while ordinary allocator initialization without
an apostrophe continues to use aggregate/association-list metadata only.

New token-cursor productions:
- Production_Qualified_Expression_Operand_Open_Delimiter
- Production_Qualified_Expression_Operand_Close_Delimiter
- Production_Qualified_Expression_Operand_Missing_Close_Recovery_Boundary

Regression coverage is in
Test_Language_Model_Token_Cursor_Qualified_Expression_Delimiters_Pass830.

This improves structural grammar coverage for Ada qualified-expression operand
parts. It is not compiler-grade type conversion disambiguation,
qualified-expression legality checking, overload resolution, compiler
invocation, LSP integration, render-side parsing, or dirty-state mutation.
