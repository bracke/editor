pass950 — call-profile filter foundation

Pass950 adds `Editor.Ada_Call_Profile_Filters`, a compiler-grade overload-resolution building block layered on `Editor.Ada_Call_Candidates` and `Editor.Ada_Call_Profile_Shapes`.

The model records stable per-candidate filter entries with call node, candidate declaration, callable/actual profile IDs, formal count, positional/named/total actual counts, filter status, source range, and deterministic fingerprint.  It preserves arity-compatible positional calls, rejects candidates with too many actuals, and classifies named-actual calls for later formal-name and defaulted-formal checking.

Regression coverage is provided by `Test_Ada_Call_Profile_Filter_Foundation_Pass950`.

Scope: this pass adds a compiler-grade overload-resolution building block.  It does not yet complete formal-name matching, defaulted-formal legality, expected-type propagation, full profile conformance, type checking, implicit conversion legality, generic contract matching, freezing/representation legality, or cross-unit semantic closure.
