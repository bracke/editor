Pass1232 - Elaboration generic shared-state final legality

This pass adds Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality.

The pass connects the final elaboration consumer with the generic/shared-state semantic chain. Elaboration conclusions for dispatching calls, generic instances, generic body replay, representation items, task activation and termination, preelaboration, Pure, Remote_Types, and Shared_Passive contexts are accepted only when final elaboration evidence agrees with cross-unit generic/shared-state closure, dispatching Global/Depends refinement, generic abstract-state replay, representation/generic shared-state evidence, and tasking/generic shared-state evidence.

Blocker families remain distinct for final elaboration, cross-unit generic/shared-state closure, dispatching Global/Depends, generic abstract-state replay, representation/generic shared-state evidence, tasking/generic shared-state evidence, elaboration order, preelaboration policy, Pure policy, Remote_Types policy, Shared_Passive policy, generic body availability, view barriers, source fingerprints, substitution fingerprints, multiple blockers, and indeterminate states.

Regression coverage is provided by Test_Ada_Elaboration_Generic_Shared_State_Final_Legality_Pass1232 and is registered in tests/src/core_suite.adb.
