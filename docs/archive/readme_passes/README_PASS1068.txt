Pass1068 adds stream attribute target-type profile conformance.

Implemented:
- Added Editor.Ada_Stream_Attribute_Profile_Conformance.
- Consumes Editor.Ada_Representation_Legality and Editor.Ada_Call_Profile_Shapes.
- Classifies Read, Write, Input, Output, and Put_Image stream attribute handlers by handler presence, ambiguity, procedure/function mode, arity, Input result subtype, target errors, and unknown profile cases.
- Preserves clause node, target, stream attribute kind, handler designator, callable-profile identity, arity, result subtype, source line, source fingerprint, and deterministic fingerprints.
- Extended Editor.Ada_Representation_Diagnostics with stream profile conformance projection and counters.
- Added AUnit coverage for stream target-profile conformance and diagnostics projection.

Invariant:
This pass is metadata-only and diagnostic-projection-only. It performs no rendering-side parsing, file IO, buffer mutation, command registration, workspace mutation, or edit application.

Compiler-grade status:
This pass adds one compiler-grade building block for stream attribute target-type profile conformance. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
