Pass1000: Expression type inference foundation

This pass adds one compiler-grade building block for full Ada expression type inference.
Full compiler-grade Ada analysis remains incomplete until later layers complete overload
resolution for all expression forms, expected-type propagation, aggregate typing,
implicit conversion legality, cross-unit type visibility, and diagnostic integration.

Implemented:

* Added Editor.Ada_Expression_Types.
* Stages deterministic expression-type metadata for parser-owned expression nodes.
* Classifies literals as universal integer, universal real, Boolean, String, null,
  or indeterminate.
* Resolves simple names through direct/enclosing visibility.
* Integrates selected-name resolution when supplied through Build_With_Selected_Names.
* Integrates call-resolution results for call-shaped expression nodes.
* Classifies numeric, Boolean, unknown operator expressions.
* Stages qualified expressions and attribute-result families.
* Preserves aggregate expressions as requiring an expected context.
* Records declaration IDs, type IDs, call-resolution IDs, static-value status,
  candidate counts, source ranges, and deterministic fingerprints.
* Adds counters for resolved, unresolved, ambiguous, static numeric, and unknown
  operator expression classifications.

Regression target:

* Test_Ada_Expression_Type_Inference_Foundation_Pass1000

