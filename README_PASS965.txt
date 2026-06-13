Editor Phase 579 pass965

This pass extends the compiler-grade static-expression foundation with fixed-point metadata.

Changed:
- Added fixed-point static type staging to Editor.Ada_Static_Expressions.
- Added Static_Fixed_Type_Info records with delta, optional digits, optional range bounds, evaluated static values, source ranges, and fingerprints.
- Added Lookup_Fixed_Type, Static_Fixed_Type_Count, Static_Fixed_Type_At, Static_Fixed_Type, and Quantize_Fixed_Value APIs.
- Added fixed-point static value statuses for representable fixed values, delta mismatches, and range errors.
- Added AUnit regression Test_Ada_Static_Fixed_Point_Foundation_Pass965.

Scope:
This is a compiler-grade static-expression/type-system building block. Complete Ada fixed-point legality, universal numeric resolution in all contexts, generic contracts, freezing/representation legality, and cross-unit semantic closure remain incomplete.
