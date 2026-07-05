Editor pass953 — Expected-type context foundation

This pass adds Editor.Ada_Expected_Type_Contexts, a compiler-grade semantic
staging layer that attaches deterministic expected-subtype context metadata to
call-shaped expression nodes after call-resolution staging.

Implemented scope:
* expected subtype extraction for object/constant/declaration defaults whose
  initializer contains a call-shaped expression;
* return-statement context hooks based on enclosing callable result subtype;
* stable expected-context IDs, source node/context node, owning region,
  resolution ID, context kind, status, expected subtype text, normalized subtype,
  source range, and deterministic fingerprint;
* AUnit regression coverage in
  Test_Ada_Expected_Type_Context_Foundation_Pass953.

This is a compiler-grade expected-type propagation building block. It does not
yet perform full type compatibility checking, implicit conversion legality,
profile conformance by expected type, generic contract matching, freezing /
representation legality, or cross-unit semantic closure.
