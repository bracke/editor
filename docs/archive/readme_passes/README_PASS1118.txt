Pass1118 — Integrated Semantic Closure

This pass adds Editor.Ada_Integrated_Semantic_Closure, a widened compiler-grade semantic building block that consolidates the broad legality layers introduced across Pass1099 through Pass1117 into one deterministic, snapshot-owned closure result.

The new model consumes/preserves blocker metadata from wide semantic legality diagnostics, overload resolution legality, staticness/range/predicate legality, accessibility/lifetime legality, contract/aspect legality, elaboration/dependence legality, unit completion/order legality, renaming/alias/visibility legality, exception/finalization legality, and representation/layout/stream integration legality.

It classifies:

- legal local semantic closure
- legal cross-unit semantic closure
- legal with/use semantic closure
- limited-view barriers
- private-view barriers
- missing dependencies
- ambiguous dependencies
- dependency lookup overflow
- stale dependencies
- rejected stale inputs
- wide legality blockers
- overload blockers
- staticness blockers
- accessibility blockers
- contract blockers
- elaboration blockers
- completion blockers
- renaming blockers
- exception/finalization blockers
- representation blockers
- multiple blockers
- indeterminate closure

It provides deterministic counters and lookup helpers by node, unit, status, context kind, dependency state, and blocker family, plus stable fingerprints for context and closure models.

Added AUnit regression:

- Test_Ada_Integrated_Semantic_Closure_Pass1118

The test is registered in tests/src/core_suite.adb.

This pass is a semantic integration pass, not a diagnostic UI projection pass. It does not introduce rendering-side parsing, file save/reload behavior, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, LSP integration, external parser generators, Python integration, or shell-script integration.
