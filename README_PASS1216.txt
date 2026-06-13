Pass1216: Cross-unit shared-state final closure legality

Added Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality.

This pass closes the cross-unit boundary for the shared-state semantic chain.  It requires final cross-unit closure, abstract/refined state evidence, volatile/atomic/shared-variable evidence, overload/type shared-state evidence, representation/freezing shared-state evidence, and tasking/protected shared-state evidence to agree before a cross-unit shared-state conclusion may remain confidently legal.

The model preserves dependency, view, state-visibility, abstract-constituent, volatile/atomic ordering, shared-variable, representation-effect, tasking-effect, generic-body, generic-backmapping, stale dependency, source-fingerprint, multiple-blocker, and indeterminate states as distinct blocker families.

Added Test_Ada_Cross_Unit_Shared_State_Final_Closure_Legality_Pass1216 and registered it in tests/src/core_suite.adb.
