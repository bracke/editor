Pass1001: Expected-type propagation beyond calls

This pass adds one compiler-grade building block for expression type inference. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as full overload resolution, complete expression typing, generic semantic closure, freezing/representation legality depth, and cross-unit semantic closure are fully integrated.

Implemented in this pass:

* Extended Editor.Ada_Expression_Types with expected-type propagation metadata:
  - expected context id
  - expected propagation status
  - expected subtype text
  - normalized expected subtype
* Added expected-propagation statuses:
  - not checked
  - no context
  - context found
  - propagated
  - compatible
  - mismatch
  - unknown
* Added static API paths that preserve old callers:
  - Build_With_Expected_Contexts
  - Build_With_Selected_Names_And_Expected
* Added syntax-local expected-context propagation for declaration defaults so non-call expressions can receive expected subtype metadata even when the call-only expected-context model has no record for the node.
* Applies expected subtype context to context-dependent expressions such as aggregates, conversions, qualified expressions, numeric operators, indeterminate expressions, and null literals.
* Classifies universal numeric literal compatibility against integer/real expected contexts.
* Added deterministic counters:
  - Expected_Context_Count
  - Expected_Propagated_Count
  - Expected_Mismatch_Count
  - Expected_Unknown_Count
* Added AUnit regression:
  - Test_Ada_Expression_Expected_Type_Propagation_Pass1001

The model remains snapshot-owned, deterministic, bounded, and editor-internal. It performs no compiler invocation, file IO, LSP interaction, rendering-side parsing, or editor state mutation.
