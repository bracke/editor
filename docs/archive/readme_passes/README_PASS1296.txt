Pass1296: Final RM integrated semantic closure legality

Adds Editor.Ada_Final_RM_Integrated_Semantic_Closure_Legality.

This pass creates the first unified trusted semantic closure boundary over the
stabilized RM-completion closure, direct RM-completion closure-consumer closure,
stabilized remaining RM edge closure, and coverage-proven remaining-edge AST
repair evidence.  It also preserves explicit gates for abstract/refined state,
volatile/atomic/shared-state effects, cross-unit closure, generic/shared-state
closure, overload/type, representation/freezing, tasking/protected, elaboration,
accessibility/lifetime, exception/finalization, predicate/invariant, and dataflow
evidence.

Accepted rows enter the final RM integrated closure only when all required
stabilized evidence is present, current or not-required, and source/substitution
fingerprints still match.  Missing or blocked prerequisites remain explicit
blockers with their original family identity preserved.  Recheck-required and
indeterminate evidence stays outside trusted downstream closure.

Added AUnit coverage:
- Test_Ada_Final_RM_Integrated_Semantic_Closure_Legality_Pass1296
