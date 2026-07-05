Pass1149 - Integrated closure repair gate application

This pass connects the Pass1148 AST coverage repair gate application model back into integrated semantic closure.

Implemented package:

- Editor.Ada_Integrated_Semantic_Closure.Repair_Gate_Application

The package consumes Editor.Ada_AST_Coverage_Repair_Gate_Application.Application_Model rows and produces integrated semantic closure rows. Cleared repair applications regain legal local closure. Cross-unit requirements remain dependency failures. Partial/indeterminate repairs remain indeterminate closure rows. Missing repairs, mismatched repairs, original semantic errors, and still-blocking enforcement rows remain coverage-gate closure blockers.

This is a semantic integration pass, not a projection pass: repaired Ada 2022 parser/AST/metadata/consumer coverage now affects whether closure can emit confident semantic conclusions after prior coverage gates suppressed them.

Added AUnit regression:

- Test_Ada_Integrated_Closure_Repair_Gate_Application_Pass1149

The test verifies that repaired parser/AST, metadata, and consumer gates become legal closure rows while unrepaired, original-error, cross-unit, and indeterminate rows remain blocked/dependency/indeterminate rows with deterministic fingerprints and lookups.
