Pass1103 widens the semantic-progress track with a snapshot-owned Ada tasking/protected legality layer.

Implemented package:

  Editor.Ada_Tasking_Protected_Legality

The package consumes Editor.Ada_Control_Flow_Legality and classifies task/protected semantics beyond the earlier statement-flow layer:

  * task type/body spec-body matching
  * protected type/body spec-body matching
  * duplicate/missing body detection metadata
  * task/protected kind/profile conformance metadata
  * entry declaration/body resolution
  * entry family index resolution, compatibility, and staticness
  * protected entry barrier presence/type/Boolean legality
  * accept statement entry/profile/task-body placement legality
  * requeue target resolution and entry-kind legality
  * requeue-with-abort permission metadata
  * protected function state-modification and entry-call restrictions
  * protected procedure barrier rejection
  * protected private-data resolution metadata
  * select alternative and linked control-flow legality propagation

Added regression:

  Test_Ada_Tasking_Protected_Legality_Pass1103

The regression is registered in tests/src/core_suite.adb and covers spec/body matching, entry profile and family-index errors, barrier checks, accept/requeue legality, protected operation restrictions, linked flow errors, deterministic counters, lookup helpers, and fingerprints.

This pass deliberately avoids another diagnostic projection/status layer. It adds a wider compiler-grade semantic building block for Ada tasking/protected legality while preserving the editor invariants: no render-side parsing, no file saves/reloads during analysis, no dirty-state mutation, no command/workspace/render mutation, deterministic bounded snapshot-owned analysis, and graceful degradation for unresolved semantic facts.
