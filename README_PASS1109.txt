Pass1109 adds Editor.Ada_Overload_Resolution_Legality.

This pass resumes compiler-grade semantic progress after the widened legality and diagnostic-feed work. It adds a snapshot-owned overload/operator resolution legality layer that consumes existing overload ranking metadata and the widened semantic-legality diagnostics bridge.

The new layer classifies exact overload selection, expected-type preference, universal integer/real preference, primitive operator preference, implicit numeric conversion, class-wide conversion, access conversion, named actual/profile evidence, defaulted formal evidence, ambiguity after preference, no visible candidate, not-visible candidate, profile mismatch, actual type mismatch, defaulted-formal mismatch, private/limited view barriers, cross-unit unresolved dependencies, linked semantic errors, unknown, and indeterminate overload states.

The package exposes deterministic context models, Add_Context fixtures, legality rows, counters, lookup helpers by node/status/kind/designator, and fingerprints. It performs no parsing, file IO, buffer mutation, command/keybinding/workspace mutation, render-side work, compiler invocation, or edit application.

AUnit regression added:

- Test_Ada_Overload_Resolution_Legality_Pass1109

The regression is registered in tests/src/core_suite.adb.
