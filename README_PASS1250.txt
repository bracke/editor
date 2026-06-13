Pass1250 — Cross-unit generic/shared-state RM completion closure legality

This pass adds Editor.Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality.

The package consumes prior cross-unit generic/shared-state final closure, generic/shared-state stabilized closure, overload/type RM completion, representation/freezing RM hard-case completion, tasking/protected RM hard-case completion, and coverage-proven AST repair evidence. A conclusion is accepted only when unit dependencies, view state, generic body/backmapping state, source/substitution fingerprints, and all required completed RM evidence agree.

Preserved blocker families include prior cross-unit generic/shared-state closure, stabilized generic/shared-state closure, overload RM completion, representation RM completion, tasking RM completion, coverage-proven AST repair, dependencies, view barriers, private-child visibility, separate-body links, generic body availability, generic backmapping, state visibility, source/substitution fingerprints, multiple blockers, and indeterminate closure.

Added regression:
Test_Ada_Cross_Unit_Generic_Shared_State_RM_Completion_Closure_Legality_Pass1250
