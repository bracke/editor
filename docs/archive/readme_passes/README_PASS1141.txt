Pass1141 -- RM-grade overload edge legality

This pass adds Editor.Ada_Overload_RM_Edge_Legality, a widened semantic legality package for remaining Ada overload-resolution edge cases that were not precise enough in the broad overload resolver and preference layer.

The pass consumes existing semantic evidence rather than reparsing source text:
- Editor.Ada_Overload_Preference_Legality from Pass1126
- Editor.Ada_Generic_Instance_Body_Semantic_Replay from Pass1140
- Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement from Pass1137

New coverage includes:
- universal integer, real, fixed, and root numeric preference edge cases
- inherited primitive and homograph hiding ambiguity
- dispatching versus nondispatching candidate ambiguity
- access-to-subprogram overload profile, mode, and result mismatch checks
- generic formal subprogram overload ambiguity
- nested generic named-actual and defaulted-formal ambiguity
- preservation of linked overload preference, generic replay, and coverage-gate blockers

The model is deterministic and snapshot-owned. It exposes row identity, source spans, designator lookup, status/kind lookup, legal/error/ambiguity counters, blocker counters, and stable fingerprints. It does not invoke an external compiler, add parser generators, mutate buffers, or project UI state.

Regression coverage:
- Test_Ada_Overload_RM_Edge_Legality_Pass1141

This pass adds one compiler-grade building block for Ada overload resolution precision. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, flow, accessibility, elaboration, representation/freezing, parser gap repair, and cross-unit semantic closure layers are fully integrated.
