Pass1028 - freezing interactions for generics, private views, and bodies

Implemented:
- Added Editor.Ada_Freezing_Interactions.
- Projects generic instantiations onto freezing-point metadata.
- Records private partial-view and private full-view freezing visibility metadata.
- Records body-region freezing contexts for completion/private-view consumers.
- Added deterministic counters for generic-instance freezes, generic target errors, private partial/full views, hidden full views, and body contexts.
- Added deterministic fingerprint contribution for all freezing-interaction records.
- Added AUnit regression Test_Ada_Freezing_Generic_Private_Body_Interactions_Pass1028.
- Updated parser coverage matrix, syntax-colouring notes, release checklist, strict runtime validation notes, and README.

This pass adds one compiler-grade building block for freezing and representation legality. Full compiler-grade Ada analysis remains incomplete until remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
