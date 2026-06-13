Pass1221 - Shared-state recheck convergence legality

This pass adds Editor.Ada_Shared_State_Recheck_Convergence_Legality.

The package consumes Pass1220 shared-state recheck application rows and classifies whether shared-state recheck evidence has converged as current, converged as not required, remained stably withheld by a preserved prerequisite blocker, remained indeterminate, or changed relative to a caller supplied previous application fingerprint.  This prevents repeated shared-state semantic rechecks from cycling on unchanged abstract/refined-state, volatile/atomic/shared-variable, overload/type, representation/freezing, tasking/protected, cross-unit, state-visibility, generic-backmapping, and fingerprint evidence while still forcing another bounded recheck when the application fingerprint changes.

The pass preserves blocker family, source node, unit/dependency/state names, source spans, source fingerprints, worklist fingerprints, eligibility fingerprints, application fingerprints, previous/current model fingerprints, and deterministic convergence fingerprints.  It exposes Count, Converged_Count, Stable_Withheld_Count, Current_Count, Changed_Count, Indeterminate_Count, Count_By_Status, Count_By_Blocker_Family, Find_By_Node, Find_By_Source_Fingerprint, and Stable_Fingerprint.

Added regression:

  Test_Ada_Shared_State_Recheck_Convergence_Legality_Pass1221

This is a shared-state semantic convergence pass, not a UI projection pass.
