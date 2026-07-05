Editor pass959

This pass adds Editor.Ada_Implicit_Conversions and threads implicit-conversion classification into Editor.Ada_Expected_Call_Filters. It distinguishes exact/subtype compatibility, universal numeric compatibility, class-wide compatibility, derived-type ancestry that requires explicit conversion, known different-root rejection, and indeterminate cases.

Added regression:
- Test_Ada_Implicit_Conversion_Filter_Foundation_Pass959

Scope: compiler-grade implicit-conversion staging for expected-call filtering. Remaining work includes complete implicit conversion coverage for all expression contexts, profile conformance, full overload resolution, generic contracts, static expression evaluation, freezing/representation legality, and cross-unit semantic closure.
