Pass1136 - Coverage-gated semantic result integration

This pass adds Editor.Ada_Coverage_Gated_Semantic_Results and Editor.Ada_Integrated_Semantic_Closure.Gated_Results.

Purpose

Pass1134 introduced semantic coverage gates and Pass1135 fed those gates into integrated closure. Pass1136 makes the gate result preserve the exact semantic conclusion family that was gated. A suppressed, degraded, repair-required, or cross-unit-required result now keeps its original conclusion kind, construct, consumer, source row, node/span, gate reason, and stable fingerprint.

Compiler-grade value

This avoids a false sense of legality when a downstream semantic layer reached a legal or derived-legal conclusion from incomplete parser, AST, metadata, or consumer coverage. It also avoids losing provenance: diagnostics can now say that the aggregate, overload, generic instance, representation, dataflow, or other semantic conclusion was suppressed because of a specific gate, instead of reducing everything to an anonymous coverage blocker.

Added packages

- Editor.Ada_Coverage_Gated_Semantic_Results
  - Converts semantic coverage gates into gated semantic result rows.
  - Preserves original conclusion family, original state, construct, consumer, gate status/action, semantic row id, source node/span, messages, and fingerprints.
  - Counts confident, suppressed, degraded, repair-required, cross-unit-required, unsafe-blocked, and original-error-preserved rows.

- Editor.Ada_Integrated_Semantic_Closure.Gated_Results
  - Converts gated semantic result rows into integrated semantic closure contexts.
  - Confident rows remain legal closure.
  - Cross-unit-required rows become dependency failures.
  - Degraded rows become indeterminate closure.
  - Suppressed, repair-required, and unsafe-blocked rows become coverage-gate closure blockers while retaining original semantic-family detail.

Tests

Added AUnit regression:

- Test_Ada_Coverage_Gated_Semantic_Results_Pass1136

The test verifies that complete coverage preserves confident legality, missing metadata requires repair, cross-unit gaps become dependency requirements, graceful-degradation-only rows suppress legal conclusions, the original semantic conclusion and consumer remain queryable, and gated rows flow into integrated semantic closure with the expected blocker/dependency status.

This pass adds one compiler-grade building block for safe semantic result gating. Full compiler-grade Ada analysis remains incomplete until every parser/AST construct and every widened semantic layer is connected to the gated result path and remaining RM legality details are fully integrated.
