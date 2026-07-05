Pass1217 adds Editor.Ada_Shared_State_Stabilized_Diagnostic_Integration.

This pass feeds Pass1216 cross-unit shared-state final closure into a stabilized diagnostic-boundary model.  Accepted shared-state closure rows are withheld as current semantic evidence, while non-legal rows are emitted with original blocker-family identity preserved.

The model preserves distinct families for cross-unit closure, abstract/refined state, volatile/atomic/shared-variable effects, overload/type shared-state evidence, representation/freezing shared-state evidence, tasking/protected shared-state evidence, dependency failures, view barriers, generic backmapping, state visibility, fingerprint mismatches, multiple blockers, and indeterminate states.

Added AUnit regression:
  Test_Ada_Shared_State_Stabilized_Diagnostic_Integration_Pass1217

This pass is semantic integration only; it does not add rendering-side parsing, command projection, palette/keybinding aliases, workspace mutation, file save/reload behavior, or external parser/compiler integration.
