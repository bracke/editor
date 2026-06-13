Pass581: retained Character constants now participate in bounded static string concatenation.

Changes:
- Added a bounded Character-constant lookup for retained discrete constants whose subtype is Character-compatible.
- Static string expression evaluation now treats named Character constants as one-character String operands for concatenation.
- Attribute-initialized Character constants such as Character'Val(Character'Pos(C)) can now initialize String constants through concatenation.
- Added AUnit regression coverage proving named Character concatenation feeds Color'Value and retained String'Length representation expressions.
