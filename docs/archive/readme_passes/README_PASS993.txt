Editor Pass 993

This pass adds one compiler-grade building block for operational attribute legality.

Implemented:
- Extended Editor.Ada_Representation_Legality with operational attribute value metadata.
- Recognizes and classifies Pack, Atomic, Volatile, Independent, Atomic_Components, Volatile_Components, Independent_Components, Suppress_Initialization, Bit_Order, Scalar_Storage_Order, and Default_Scalar_Storage_Order clauses.
- Checks Boolean-valued operational attributes for static True/False values.
- Checks storage-order attributes for High_Order_First and Low_Order_First values.
- Adds target-shape checks for composite-only, array-component-only, type/object, and storage-order operational attributes.
- Adds deterministic operational error/value/target counters.
- Adds AUnit regression Test_Ada_Operational_Attribute_Legality_Pass993.

Full compiler-grade Ada analysis remains incomplete until remaining layers such as cross-unit semantic closure, richer expression type inference, deeper representation legality for all operational properties, generic/private-view closure, and diagnostic integration are fully integrated.
