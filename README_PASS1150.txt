Pass1150 - Repair-gated diagnostic integration

This pass adds Editor.Ada_Repair_Gated_Diagnostic_Integration.

The pass completes the repair/gate feedback loop started in Pass1147-Pass1149:

  coverage audit -> semantic coverage gates -> widened legality enforcement ->
  concrete coverage repair -> repair gate application -> integrated closure ->
  repair-gated diagnostic integration.

The new package consumes repair-applied coverage-gate rows together with the
integrated semantic closure rows produced from them.  It classifies whether each
row should regain a confident non-diagnostic semantic result, emit an error,
emit a warning, require cross-unit closure, preserve an original semantic error,
or reject stale input.  This prevents repaired constructs from continuing to
look broken in diagnostics while also preventing unrepaired parser/AST/metadata
or consumer gaps from being reported as confident legal semantic conclusions.

The integration preserves application row identity, integrated closure row
identity, application status, closure status, blocker family, dependency state,
node/span, message/detail, source fingerprints, counters, deterministic lookups,
and stable model fingerprints.

Added AUnit regression:

  Test_Ada_Repair_Gated_Diagnostic_Integration_Pass1150

The regression verifies that cleared parser/metadata/consumer repairs withhold
diagnostics and regain confident closure, unrepaired and original semantic errors
remain errors, dependency and indeterminate rows remain warnings, and stale
repair-gated inputs are rejected instead of emitted as current diagnostics.
