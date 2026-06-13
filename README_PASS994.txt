# Pass994 — Representation/aspect legality unification

This pass adds one compiler-grade building block for Ada representation and operational legality: representation-property aspects are now staged through the same legality model as attribute-definition clauses.

Implemented:

- `Editor.Ada_Representation_Legality` now records the source form for every representation-property check.
- Aspect associations such as `Pack`, `Atomic`, `Atomic_Components`, `Bit_Order`, `Scalar_Storage_Order`, `Address`, `Convention`, `Import`, `Export`, stream attributes, and size/alignment/storage properties are synthesized into the same representation-legality classification path as attribute-definition clauses.
- Aspect defaults such as Boolean aspects without an explicit value are normalized conservatively to `True` before legality classification.
- Added deterministic counters:
  - `Aspect_Source_Count`
  - `Attribute_Definition_Source_Count`
  - `Unified_Property_Count`
- Added AUnit regression:
  - `Test_Ada_Representation_Aspect_Unification_Pass994`

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as cross-unit semantic closure, full expression type inference, private-view use in every semantic consumer, deeper representation property rules, and diagnostics integration are fully integrated.
