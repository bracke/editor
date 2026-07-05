Pass1159 — Representation/freezing tasking elaboration-flow consumer legality

This pass adds one compiler-grade building block for representation/freezing legality.

New package:
  Editor.Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality

Purpose:
  Representation/freezing exact propagation now consumes tasking/protected
  elaboration contract-flow results. Representation clauses, operational
  attributes, stream attributes, record layouts, generic instance representation
  effects, private/full-view representation timing, and finalization/abortable
  tasking effects cannot remain confidently legal when task activation,
  protected operation, accept/requeue/select, or abortable elaboration
  contract-flow evidence is missing, blocked, or indeterminate.

Semantic classifications include:
  * accepted representation clauses, operational attributes, stream attributes,
    record layouts, generic-instance effects, private/full-view effects,
    task activation/termination effects, protected read/write/call effects,
    entry barriers, accept bodies, requeue/select effects, and abortable
    finalization effects;
  * base representation/freezing propagation errors;
  * missing tasking elaboration-flow evidence;
  * Refined_Global missing read/write, mode mismatch, and extra item blockers;
  * Refined_Depends missing/extra edge and source/target mode blockers;
  * unpropagated tasking call effects;
  * repaired coverage feedback blockers;
  * linked flow graph, contract-flow, elaboration, and tasking-effect blockers;
  * multiple matching tasking-flow blockers and indeterminate rows.

Regression added:
  Test_Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality_Pass1159

This is not a diagnostic/projection pass. It deepens a legality consumer by
connecting tasking/protected elaboration-flow evidence to representation/freezing
confidence.
