Editor Phase 579 Pass1106

Pass1106 adds Editor.Ada_Cross_Unit_Semantic_Closure.

Scope:
- Connect cross-unit dependency and lookup state to the widened semantic legality layers from Pass1099 through Pass1105.
- Classify cross-unit semantic closure for assignment, return, expression/conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance, representation, and visibility contexts.
- Preserve missing/ambiguous/overflow dependency states, limited/private view barriers, with/use visibility, and local-only contexts.
- Preserve linked legality statuses from assignment, return, expression, flow, tasking, tagged, and generic-instance models.
- Provide deterministic counters, status/kind/source-unit/target-unit/lookup-name helpers, and fingerprints.

Regression:
- Test_Ada_Cross_Unit_Semantic_Closure_Pass1106.
- Registered in Core_Suite.

Invariants:
- No rendering-side parsing.
- No file save/reload.
- No dirty-state mutation.
- No command, keybinding, workspace, or render mutation.
- No compiler invocation, LSP, external parser generator, Python, or shell-script integration.
