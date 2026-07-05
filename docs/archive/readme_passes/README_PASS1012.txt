# Editor Pass1012

Pass1012 adds one compiler-grade building block for expression type analysis: parameter-association expected-type propagation.

Implemented in `Editor.Ada_Expression_Types`:

- Added deterministic parameter-association inference metadata for positional, named, and generic association-shaped actual nodes that are owned by call-shaped syntax nodes.
- Resolves the callable designator through existing call-resolution metadata when available, falling back to direct/enclosing visibility when the call-resolution layer has not selected a declaration.
- Parses callable formal profiles conservatively from parser-owned declaration labels and maps positional and named actuals to their target formal parameter subtype.
- Propagates formal expected subtype metadata into actual expressions and classifies actual/formal compatibility, mismatch, unresolved formal context, ambiguous formal context, and unknown cases.
- Adds parameter-association metadata to deterministic expression fingerprints.
- Adds counters for parameter-association context, propagation, mismatch, and unknown cases.

Regression coverage:

- `Test_Ada_Expression_Parameter_Association_Propagation_Pass1012`

This pass remains parser-owned, deterministic, bounded, and free of rendering-side parsing, file saves/reloads, dirty-state mutation, or command/workspace/render mutation leaks. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as expression-typed call resolution, operator overload resolution, universal numeric finalization, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
