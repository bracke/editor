# Editor Phase 579 Pass 949 — Call-profile shape foundation

Pass949 adds `Editor.Ada_Call_Profile_Shapes`, a compiler-grade overload-resolution building block layered on the parser-owned syntax tree and declarative-region model.

The new model extracts deterministic callable-profile metadata from subprogram, formal subprogram, entry, and entry-body declarations, including normalized name, owning region, formal-parameter count, result presence, result subtype text, source range, status, and fingerprint.  It also extracts actual-argument shape metadata from function-call and call-statement syntax nodes, including positional actual count, named actual count, total actual count, owning region, normalized call designator, status, and fingerprint.

Regression coverage is provided by `Test_Ada_Call_Profile_Shape_Foundation_Pass949`.

This is a compiler-grade semantic foundation for later overload filtering by arity and named-actual shape.  It does not yet implement expected-type propagation, full profile conformance, type checking, implicit conversion legality, generic contract matching, freezing/representation legality, or cross-unit semantic closure.
