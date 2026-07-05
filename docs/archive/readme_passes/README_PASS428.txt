Editor  IDE-grade outline/semantic language model pass428

Implemented a focused Ada token-cursor grammar pass for attribute references with argument parts.

Changes:
- Added Production_Attribute_Argument_Part to Editor.Ada_Token_Cursor.
- Attached parenthesized attribute arguments to Production_Attribute_Reference rather than leaving them to the generic name-suffix loop.
- Preserved reduction attribute metadata for Values'Reduce-style forms while parsing the argument association list structurally.
- Added AUnit regression coverage for Values'First (1), Integer'Image (Value), and Values'Reduce ("+", 0).
- Updated validation/release guards and documentation.

Scope note:
This improves Ada attribute-reference grammar coverage. It does not perform compiler-grade attribute legality, prefix legality, attribute result typing, expected-type resolution, or reduction semantics.
