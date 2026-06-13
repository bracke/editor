Editor Phase 579 pass1013 — call resolution using actual expression types

This pass adds one compiler-grade building block for Ada expression type analysis.
Full compiler-grade Ada analysis remains incomplete until the remaining layers such
as overload resolution, type checking, generic contracts, freezing/representation
legality, and cross-unit semantic closure are fully integrated.

Implemented in this pass:

* Extended Editor.Ada_Expression_Types with call actual type-resolution metadata.
* Call-shaped expression/statement nodes now retain actual-expression compatibility
  counters derived from the selected callable profile when direct visibility or
  call-resolution metadata identifies the callee.
* Positional and named actuals are compared against the corresponding formal
  subtype text using the existing conservative expression subtype inference path.
* Calls are classified as actual-type compatible, actual-type mismatch, unknown,
  unresolved, or ambiguous without invoking a compiler or mutating editor state.
* Added deterministic counters:
  - Call_Actual_Type_Compatible_Count
  - Call_Actual_Type_Mismatch_Count
  - Call_Actual_Type_Unknown_Count
  - Call_Actual_Type_Ambiguous_Count
* Added AUnit regression:
  - Test_Ada_Expression_Call_Actual_Type_Resolution_Pass1013

The model remains deterministic, bounded, parser-owned, and suitable for later
IDE diagnostics and semantic-colouring consumers.
