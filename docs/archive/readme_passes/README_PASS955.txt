Editor pass955

This pass adds a conservative subtype-compatibility foundation for the compiler-grade Ada semantic pipeline.

Changed:
- Added `Editor.Ada_Subtype_Compatibility`.
- Added normalized subtype-name handling for expected/actual subtype comparisons.
- Added numeric-family classification for predefined integer/real families and universal numeric markers.
- Added compatibility statuses for exact matches, universal integer to integer, universal real to real, universal integer to real, known numeric incompatibility, and indeterminate user-defined relationships.
- Extended `Editor.Ada_Expected_Call_Filters` so expected-call filtering records compatibility status and distinguishes exact matches, compatible universal-numeric cases, known mismatches, and indeterminate relationships.
- Added AUnit regression `Test_Ada_Subtype_Compatibility_Foundation_Pass955`.

Scope:
This is a compiler-grade type-checking building block. It does not yet provide the complete Ada type graph, derivation compatibility, class-wide compatibility, implicit conversions, full static expression evaluation, generic contract matching, freezing/representation legality, or cross-unit semantic closure.
