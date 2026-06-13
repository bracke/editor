Pass1211 -- Abstract / Refined State Legality

This pass adds Editor.Ada_Abstract_State_Refined_State_Legality.

The pass models abstract state declarations, Refined_State aspects, constituent mappings, abstract-state Global/Depends use, cross-unit state visibility, task/protected shared-state effects, volatile state effects, and atomic state effects.

It consumes final flow/contract proof evidence, deep tasking/protected evidence, and stabilized final semantic closure evidence before allowing an abstract/refined-state conclusion to remain confidently legal.

Preserved blockers include missing abstract state declarations, duplicate abstract states, missing Refined_State aspects, missing/extra constituents, constituent mode mismatch, invisible constituents, abstract Global mode mismatch, missing/extra abstract Depends edges, refinement cycles and overflows, missing or blocked flow proof rows, missing or blocked tasking rows, missing or blocked stabilized closure rows, volatile/atomic effect blockers, source fingerprint mismatches, multiple blockers, and indeterminate state.
