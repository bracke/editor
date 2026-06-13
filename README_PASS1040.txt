Pass1040 - representation/freezing diagnostics projection

This pass adds Editor.Ada_Representation_Diagnostics, a projection-only diagnostics layer over representation and freezing semantic metadata.

The model consumes:
- Editor.Ada_Representation_Legality
- Editor.Ada_Record_Layout_Validation
- Editor.Ada_Record_Storage_Order_Rules
- Editor.Ada_Operational_Attribute_Rules
- Editor.Ada_Aspect_Inheritance_Rules
- Editor.Ada_Freezing_Interactions

It emits deterministic diagnostics for unresolved or invalid representation targets, freezing-order errors, static-value errors, record component errors, enumeration representation errors, address/interfacing/stream/operational errors, record-layout overlap/static errors, storage-order conflicts, operational duplicates/conflicts, aspect-inheritance conflicts, private-view freezing, and generic-instance freezing interactions.

The package is snapshot-owned and projection-only. It performs no parsing, file IO, editor mutation, command registration, workspace mutation, or rendering work.

Regression coverage:
- Test_Ada_Representation_Diagnostics_Projection_Pass1040

This pass adds one compiler-grade building block for representation/freezing diagnostics. Full compiler-grade Ada analysis remains incomplete until remaining layers such as full overload resolution, full type checking, complete generic contracts, complete freezing/representation legality, and cross-unit semantic closure are fully integrated.
