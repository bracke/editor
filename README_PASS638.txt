Editor Phase 579 - Pass 638

Focus: qualified-expression part grammar.

Changes:
- Added token-cursor production events for the qualifier subtype-mark side and the parenthesized operand side of qualified expressions.
- Routed ordinary qualified expressions such as T'(Value) through the new part-level productions.
- Routed allocator qualified expressions such as new T'(Value) through the same part-level productions while preserving allocator-specific classification.
- Preserved selected-name qualifier handling before the qualification apostrophe, including selected operator-symbol subtype marks.
- Added AUnit regression coverage for ordinary, nested, aggregate-like, allocator, and selected-subtype qualified-expression forms.

Scope:
This improves structural grammar coverage for Ada qualified-expression subtype marks and operands. It is not compiler-grade legality checking for subtype compatibility, aggregate legality, allocator accessibility, or qualification legality.
