Pass1156 - contract flow/refinement consumer legality

This pass adds Editor.Ada_Contract_Flow_Refinement_Consumer_Legality.

The pass connects refined flow-effect consumer legality back into contract/aspect legality. Global, Depends, Refined_Global, and Refined_Depends contract aspects no longer remain confidently legal merely because the base contract row was legal; the matching flow-refinement consumer row must also accept the effect.

The checker classifies legal Global and Depends aspects, legal Refined_Global and Refined_Depends refinements, legal call propagation, generic effects, and task/protected effects. It preserves and reports base contract errors, missing consumer rows, missing Refined_Global reads/writes, Refined_Global mode mismatches and extra items, missing/extra Refined_Depends edges, source/target mode errors, unpropagated call effects, coverage-feedback blockers, linked flow graph errors, multiple consumer blockers, and indeterminate consumer state.

Regression coverage is provided by Test_Ada_Contract_Flow_Refinement_Consumer_Legality_Pass1156 and is registered in tests/src/core_suite.adb.

This is a semantic-depth pass. It is not a diagnostic projection, status, palette, keybinding, workspace, or render layer.
