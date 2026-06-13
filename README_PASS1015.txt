Pass1015 — universal numeric final resolution with expected contexts

This pass adds one compiler-grade expression-type building block for final resolution of universal integer and universal real expressions.

Implemented:

* Editor.Ada_Expression_Types now stages Universal_Numeric_Resolution_Status metadata.
* Universal integer expressions are resolved into expected integer, modular, real, or fixed-point contexts where the context is available.
* Universal real expressions are resolved into expected real or fixed-point contexts where the context is available.
* Static numeric values are retained on the expression-type record for diagnostic consumers.
* Integer subtype range metadata from Editor.Ada_Static_Expressions is used to preserve compatible and out-of-range universal integer values.
* New deterministic counters expose resolved, range-error, mismatch, and unknown universal-numeric cases.
* Universal numeric metadata contributes to expression-type fingerprints.

AUnit coverage:

* Test_Ada_Expression_Universal_Numeric_Final_Resolution_Pass1015

The implementation remains parser-owned, deterministic, bounded, and snapshot-owned. It does not invoke a compiler, external parser, LSP server, file reload, file save, rendering-side parse path, or dirty-state mutation.

Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
