Pass 533 - Top-level-safe fallback pragma target association stripping

This pass hardens the remaining fallback path in pragma target extraction.

Implemented:
- Replaced raw Index-based `=>` / comma scanning in `Pragma_Target` with a
  character-literal-, string-literal-, and parenthesis-aware top-level scanner.
- `pragma Pack (Entity => Rec)` and similar fallback entity pragmas still strip
  the outer named-association label.
- Nested association arrows inside expression values are now ignored by this
  final target-stripping path, matching the already hardened pragma argument
  and named-target scanners.
- Prevents fallback target binding from jumping into nested values such as
  `Entity => Pick (Kind => Value)`.

This keeps representation/operational pragma lowering aligned with the common
aspect / attribute-definition legality path without adding another parallel
property table.
