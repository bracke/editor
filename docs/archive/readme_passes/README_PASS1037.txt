Pass1037 — Generic object default-expression type conformance

This pass adds one compiler-grade building block for generic formal-object contracts. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Implemented:
- Added Editor.Ada_Generic_Object_Default_Type_Conformance.
- Compares formal-object defaults and explicit object actuals against the formal object's expected subtype.
- Uses Editor.Ada_Static_Expressions for numeric static value classification.
- Uses Editor.Ada_Type_Graph and staged subtype-bound metadata for static range-error detection.
- Preserves compatible defaults, compatible explicit actuals, type mismatches, range errors, unknown static values, missing actuals/defaults, and unknown formal subtype cases as deterministic metadata.
- Added counters for compatible, mismatch, range-error, unknown, default-checked, and actual-checked cases.
- Added AUnit regression Test_Ada_Generic_Object_Default_Type_Conformance_Pass1037.

The pass is snapshot-owned and projection-only. It does not add rendering-side parsing, file saves/reloads, command aliases, keybindings, workspace mutation, or dirty-state mutation.
