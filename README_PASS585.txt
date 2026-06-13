Pass585: qualified static String prefixes feed indexing and slicing.

Implemented:
- Reworked bounded static string indexing to locate the final top-level index operation instead of rejecting prefixes containing an apostrophe.
- Reworked bounded static string slicing with the same top-level suffix locator.
- Qualified String expressions such as String'("Green") (1) and String'("Green") (1 .. 2) can now feed Character constants, scalar Value, and representation-expression static values.
- Existing out-of-range index/slice rejection and static-value diagnostics remain unchanged.

Scope:
- This is still bounded static evaluation for the editor semantic model, not full Ada compile-time evaluation.
