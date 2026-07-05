Editor Pass1130

This pass adds a compiler-grade building block for tasking/protected precision legality.

Implemented package:

- Editor.Ada_Tasking_Protected_Precision_Legality

The package deepens the existing Pass1103 tasking/protected legality model by connecting protected-state effects, entry-barrier dataflow, accept/requeue/select flow, queued entry-call accessibility, and task activation/elaboration precision.

Semantic coverage added:

- task activation elaboration errors
- task body elaboration-before-use checks
- protected function state-write rejection
- protected function entry-call rejection
- protected function Global/Depends write-effect rejection
- protected procedure barrier rejection
- protected procedure Global/Depends mismatch classification
- protected entry missing/non-Boolean barriers
- barrier read-before-write from dataflow integration
- barrier Global/Depends mismatch classification
- entry-family index staticness/type compatibility
- accept outside task body and profile mismatch
- requeue target unresolved/non-entry and with-abort restrictions
- select alternative open/terminate-delay conflict metadata
- queued entry-call accessibility risks
- protected-state uninitialized/use-after-finalization checks
- linked base tasking, dataflow, elaboration, and accessibility blockers

Regression added:

- Test_Ada_Tasking_Protected_Precision_Legality_Pass1130

This pass deliberately avoids command/palette/status/render projection work. It adds real semantic checking and reduces false positives/false negatives by making tasking/protected legality consume newer dataflow, elaboration, and accessibility precision layers.
