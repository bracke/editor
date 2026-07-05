Pass 576 - Static integer Value evaluation

Implemented a bounded static-evaluation extension for scalar integer Value attributes.

Highlights:
- Added retained evaluation for Integer/Natural/subtype `T'Value (String_Expression)` when the operand is a bounded static string expression.
- Reuses the static string environment built by earlier passes, including literals, concatenation, slices/indexing, and Image-derived strings.
- Range-checks the parsed integer result against the Value prefix subtype before it enters natural/signed representation arithmetic.
- Supports signed range metadata such as `Low : constant := Integer'Value ("-4")` and later use through `Offset'Last`.
- Keeps out-of-range forms such as `Natural'Value ("-1")` nonstatic so existing static-value diagnostics are emitted.
- Added regression coverage for direct Natural'Value in Size, Integer'Value feeding signed range bounds, typed constants initialized by Value, and out-of-range Natural'Value rejection.
