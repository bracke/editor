# Editor Phase 579 pass969

Pass969 extends `Editor.Ada_Generic_Contracts` with deterministic formal subprogram profile conformance metadata for generic instantiations.

Implemented changes:

* Generic formal subprogram records now retain parameter count, normalized parameter subtype shape, result presence, and normalized result subtype.
* Generic instantiation actual records now retain positional and named actual designator text in addition to actual-kind metadata.
* Generic formal/actual matching now resolves declaration-shaped subprogram actuals through direct visibility and compares their profile shape against the corresponding formal subprogram.
* Formal type actual substitution is applied for simple generic contract profile checks, so a formal profile using `Element` can match an actual subprogram profile using the instance actual type such as `Integer`.
* Mismatch metadata distinguishes formal-kind mismatch from formal subprogram profile mismatch.
* AUnit regression coverage was added in `Test_Ada_Generic_Formal_Subprogram_Profile_Conformance_Pass969`.

Scope:

This is a compiler-grade generic-contract building block for formal subprogram profile conformance. Remaining work includes overload-aware subprogram actual selection, default-expression legality, formal package contract matching, generic body contract visibility, private-view rules, freezing/representation legality, and cross-unit semantic closure.
