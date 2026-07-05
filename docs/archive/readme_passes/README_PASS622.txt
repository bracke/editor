Pass 622 - Base Value nested operand scanner parity

- Reused the pass621 literal/parenthesis-aware Value operand scanner for chained scalar `T'Base'Value (...)` attributes.
- `T'Base'Value` operands such as `Color'Base'Image (Blue)` are now scanned as complete static string operands instead of being truncated at the nested Image right parenthesis.
- Kept the same integer-string fallback path as direct `T'Value` for integer-like static Value operands.
- Cleaned the discrete Value regression harness around the direct Base-Value case so the bad named-string diagnostics are explicitly declared and checked in that pass.
