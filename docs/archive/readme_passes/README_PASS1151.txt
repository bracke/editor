Pass1151 — Repair-gated diagnostic provenance

This pass adds Editor.Ada_Repair_Gated_Diagnostic_Provenance.

It consumes Editor.Ada_Repair_Gated_Diagnostic_Integration rows from Pass1150 and preserves repair-gated diagnostic decisions as deterministic provenance rows.  Repaired constructs that regain confident closure are traced as restored/withheld diagnostics.  Remaining parser/AST/metadata/consumer blockers are traced as errors, cross-unit requirements and indeterminate repairs remain warnings, preserved original semantic errors remain errors, and stale repair-gated inputs are traced as rejected rather than current diagnostics.

The pass adds:

- src/core/editor-ada_repair_gated_diagnostic_provenance.ads
- src/core/editor-ada_repair_gated_diagnostic_provenance.adb
- tests/src/test_ada_repair_gated_diagnostic_provenance_pass1151.ads
- tests/src/test_ada_repair_gated_diagnostic_provenance_pass1151.adb

The AUnit regression is registered in tests/src/core_suite.adb.

This pass continues the widened semantic direction by making the repair/gate/closure/diagnostic path explainable end-to-end.  It does not add UI, command, keybinding, workspace, render, file IO, compiler invocation, external parser generation, or parser-side mutation behavior.
