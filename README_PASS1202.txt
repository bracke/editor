Pass1202 - Final semantic remediation diagnostic integration

This pass adds Editor.Ada_Final_Semantic_Remediation_Diagnostic_Integration and extends the unified semantic diagnostic feed with Build_With_Final_Remediation_Diagnostics.

The pass consumes Pass1201 final semantic remediation closure rows and converts unresolved prerequisite closure blockers into diagnostic-ready rows while preserving the original blocker family. It deliberately avoids UI projection/status churn: stale snapshot evidence, AST/coverage repair, cross-unit closure, view barriers, generic replay/backmapping, overload/type evidence, representation/freezing, flow/contract proof, tasking/protected effects, elaboration, accessibility/lifetime, discriminant/variant evidence, preserved semantic errors, and indeterminate states remain distinct through the feed path.

The package is deterministic, bounded, snapshot-owned, and side-effect-free. It performs no rendering-side parsing, file IO, save/reload, dirty-state mutation, command/keybinding/workspace/render mutation, LSP use, compiler invocation, external parser generation, Python, or shell scripting.

AUnit coverage: Test_Ada_Final_Semantic_Remediation_Diagnostic_Integration_Pass1202 verifies one-row-per-closure preservation, withheld legal rows, emitted blocker rows, blocker-family queries, downstream-blocked totals, feed source mapping for cross-unit and generic blockers, stale-input feed rejection, and stable fingerprints.
