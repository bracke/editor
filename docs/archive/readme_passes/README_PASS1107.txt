Pass1107 adds Editor.Ada_Wide_Semantic_Legality_Diagnostics, a widened semantic diagnostic bridge for the compiler-grade legality layers added in Pass1099 through Pass1106.

The package consumes snapshot-owned assignment, return, conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance/freezing/representation, and cross-unit semantic closure models. It exposes their failing legality states as one deterministic diagnostic model with severity, family, kind, node, span, original legality status, stable source fingerprints, deterministic result fingerprints, counters, and lookup helpers.

This pass is deliberately semantic rather than UI-projection churn. It makes the newer legality layers visible as compiler-grade diagnostic facts while preserving the editor invariants: no rendering-side parsing, no file saves/reloads during analysis, no dirty-state mutation, no command/keybinding/workspace/render mutation leaks, and deterministic snapshot-owned results.

Added AUnit regression:
- Test_Ada_Wide_Semantic_Legality_Diagnostics_Pass1107

Registered in:
- tests/src/core_suite.adb
