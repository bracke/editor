Pass1117 — Representation / layout / stream integration legality

This pass adds Editor.Ada_Representation_Layout_Stream_Integration_Legality, a widened compiler-grade semantic building block that connects representation legality, exact record layout validation, stream attribute profile conformance, generic-instance freezing/representation effects, accessibility/lifetime legality, staticness/range/predicate legality, unit-completion/order legality, contract/aspect legality, and exception/finalization legality.

The pass is snapshot-owned and deterministic. It performs no parsing, file IO, save/reload, dirty-state mutation, command routing, keybinding/workspace/render mutation, or compiler invocation.

The new layer classifies legal representation items, legal record layouts, legal stream attributes, legal operational attributes, legal convention items, legal generic-instance representation effects, and legal finalization effects. It also classifies unresolved/ambiguous targets, target-kind mismatches, after-freezing representation items, static/address/convention/operational errors, exact record size/alignment/component errors, variant layout holes and overlaps, discriminant layout errors, stream handler/profile/mode/result errors, generic-instance freezing and representation errors, accessibility/staticness/completion/contract/exception linked errors, private/limited view barriers, cross-unit unresolved states, and indeterminate cases.

Added regression: Test_Ada_Representation_Layout_Stream_Integration_Legality_Pass1117.
Registered the regression in tests/src/core_suite.adb.

This pass deliberately continues the post-Pass1099 policy: semantic rule-completion and cross-layer legality integration take priority over IDE projection churn.
