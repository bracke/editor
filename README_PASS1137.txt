Editor Phase 579 - Pass1137

This pass implements widened legality coverage-gate enforcement.

Pass1136 preserved coverage-gated semantic results and connected them to integrated closure. Pass1137 makes the gate result consumable by widened legality engines before they preserve a confident legality conclusion.

Added package:

  Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement

The package maps coverage-gated semantic conclusions to widened legality engines:

  assignment
  return
  conversion / access / aggregate
  call / overload
  staticness / range / predicate
  accessibility / lifetime
  contract / aspect
  dataflow / Global / Depends
  generic instance body
  record / variant aggregate
  elaboration
  tasking / protected
  representation / freezing
  exception / finalization
  integrated closure

It enforces whether a semantic row may remain confident, must preserve an original error, must degrade to indeterminate, must require cross-unit closure, must suppress legal or derived-legal results, or must block because parser/AST coverage, semantic metadata, consumer integration, or unsafe coverage is incomplete.

Added AUnit regression:

  Test_Ada_Widened_Legality_Coverage_Gate_Enforcement_Pass1137

The regression covers confident assignment results, parser/AST blockers, metadata blockers, cross-unit requirements, consumer-integration blockers, graceful-degradation suppression, original-error preservation, engine mapping, counters, lookups, and stable fingerprints.

This pass is a semantic enforcement pass, not a projection/status pass. It prevents widened semantic legality engines from producing confident legal outcomes from incomplete parser/AST/metadata coverage.
