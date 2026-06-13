Pass 578: static string expression prefix indexing/slicing

Implemented another bounded static-evaluation improvement in the Ada semantic projection:

- Static string indexing now accepts any retained bounded static string expression as the prefix, not only a named string constant.
- Static string slicing now accepts any retained bounded static string expression as the prefix, not only a named string constant.
- Direct string literals such as "Green" (1) can now initialize Character static constants.
- Direct string literal slices such as "Green" (1 .. 2) can now feed scalar Value expressions through concatenation.
- Existing range diagnostics are preserved: out-of-range indexes/slices remain nonstatic and continue to emit the existing static-value diagnostic when used in representation expressions.
- Extended regression coverage for direct-literal indexing and slicing in the static string/Value path.

Scope remains intentionally bounded to retained static string expressions and does not infer arbitrary array objects.
