Pass1351 - RM Gap Burn-Down Pass 9

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1351 and
Test_Ada_RM_Gap_Burn_Down_Pass1351.

The pass burns down the control-flow / exception / initialization /
finalization composition gap.  It requires one canonical source-shaped result
across:

* function/procedure return flow, return expression type compatibility, return
  accessibility, No_Return fall-through, unreachable statements, exit targets,
  goto targets, deeper-scope transfers, and protected-action transfer barriers;
* object declarations requiring initialization, default-expression legality,
  deferred constant completion matching, out-parameter definite assignment,
  aggregate initialization consumption, and subtype/predicate initialization
  consumption;
* raise statement/expression exception identity and visibility, handler choice
  presence, duplicate/unreachable handlers, reraise-in-handler legality, and
  local-handler versus propagation evidence;
* controlled Initialize/Adjust/Finalize profile compatibility, finalization
  ordering, limited-controlled blockers, controlled component initialization,
  exception propagation finalization hazards, abort finalization, and task
  finalization agreement;
* legal-with-runtime-check preservation for constraint, predicate,
  accessibility, and finalization paths;
* private/limited/incomplete/generic-formal/missing-view/cross-unit/control-flow
  /definite-assignment/exception/finalization/lifetime-effect indeterminate
  states;
* semantic consumer agreement for diagnostics, hover/details, semantic
  colouring, outline/navigation-style consumers, and the build-diagnostic bridge;
* source, AST, type, flow, initialization, exception, finalization, profile,
  substitution, effect, and consumer fingerprint freshness.

The pass follows the RM gap burn-down strategy: it is not a status/projection
wrapper; it adds concrete legality gates and balanced AUnit scenarios for legal,
illegal, legal-with-runtime-check, and indeterminate source-shaped cases.
