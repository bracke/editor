Pass1213 adds Editor.Ada_Overload_Shared_State_RM_Edge_Legality.

This pass deepens overload/type RM edge handling by requiring abstract/refined-state and volatile/atomic/shared-state evidence before final overload/type conclusions remain confident.  It connects prefixed calls, dispatching calls, access-to-subprogram calls, controlling-result selections, inherited primitives, generic formal subprogram calls, renamed primitives, and universal numeric operators to Pass1189 final RM evidence, Pass1211 abstract/refined-state evidence, and Pass1212 volatile/atomic/shared-state evidence.

It preserves blockers for missing or blocked final RM rows, missing or blocked shared-state rows, missing or blocked abstract-state rows, volatile effect blockers, atomic effect blockers, shared-variable blockers, protected-effect blockers, dispatching/access/generic/renaming effect mismatches, universal numeric state ambiguity, fingerprint mismatches, multiple blockers, and indeterminate state.
