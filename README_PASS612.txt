Pass 612 - Character-literal-safe copied String Range dimension scan

- Tightened copied String range-attribute dimension scanning so it skips Ada string literals and character literals while locating the optional attribute-argument parentheses.
- This keeps expressions such as `Offset_Name'Range (1 + Character'Pos (')') - Character'Pos (')'))` from being rejected by the shallow scanner before the bounded static integer evaluator can process them.
- Dimension values still must statically evaluate to `1` in the bounded one-dimensional String model.
- Added regression coverage for character-literal-bearing copied String `Range` dimension expressions feeding retained constrained-subtype bounds and representation static values.
