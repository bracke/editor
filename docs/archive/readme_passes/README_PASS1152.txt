Pass1152 - Repaired coverage semantic feedback

This pass adds one compiler-grade building block for applying repaired parser/AST/metadata/consumer coverage back into real Ada legality consumers.

Implemented:
- Added src/core/editor-ada_repaired_coverage_semantic_feedback.ads
- Added src/core/editor-ada_repaired_coverage_semantic_feedback.adb
- Added tests/src/test_ada_repaired_coverage_semantic_feedback_pass1152.ads
- Added tests/src/test_ada_repaired_coverage_semantic_feedback_pass1152.adb
- Registered the new AUnit test in tests/src/core_suite.adb

Semantic behavior:
- Consumes Editor.Ada_AST_Coverage_Repair_Gate_Application rows.
- Consumes Editor.Ada_Repair_Gated_Diagnostic_Integration rows.
- Produces repaired-coverage feedback rows for individual widened legality engines.
- Classifies structurally restored constructs, metadata-restored constructs, consumer-restored constructs, cross-unit metadata restoration, already-confident constructs, missing repairs, partial repairs, repair mismatches, indeterminate rows, preserved original semantic errors, required cross-unit closure, and stale/rejected inputs.
- Exposes Is_Eligible_For_Engine so assignment, return, conversion/access/aggregate, overload, generic, flow/dataflow, tasking/protected, elaboration, representation/freezing, exception/finalization, and integrated-closure consumers can reject stale or unrepaired coverage instead of treating a cleared gate as a blanket success.
- Preserves deterministic node, construct, consumer, source span, source fingerprint, and feedback fingerprint metadata.

Why this is semantic progress:
- Pass1147-P1151 made coverage repair visible through gate application, integrated closure, diagnostic integration, and provenance.
- Pass1152 feeds the repaired coverage result back toward the legality engines themselves.
- A repaired construct is now either explicitly eligible for a specific legality engine or remains a blocker/indeterminate/dependency/original-error row.

Regression:
- Test_Ada_Repaired_Coverage_Semantic_Feedback_Pass1152 checks restored parser/AST coverage, metadata repair, consumer integration repair, engine eligibility, blocker preservation, cross-unit requirements, original semantic error preservation, indeterminate repair handling, and stale diagnostic rejection.

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
