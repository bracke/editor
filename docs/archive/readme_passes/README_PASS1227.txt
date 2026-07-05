Pass1227 adds Editor.Ada_Generic_Abstract_State_Replay_Legality.

This pass adds one compiler-grade building block for generic abstract/refined-state replay.  Generic bodies and nested instantiations now receive a legality layer that requires source/instance backmapping, nested generic closure, abstract-state consumer evidence, volatile/atomic/shared-state evidence, dispatching Global/Depends refinement evidence, and stabilized shared-state closure before accepting replayed abstract/refined-state effects.

The pass preserves distinct blocker families for source-instance backmapping, nested generic closure, abstract-state consumers, volatile/atomic shared-state proof, dispatching Global refinement, stabilized shared-state closure, formal/actual substitution, source fingerprints, substitution fingerprints, multiple blockers, and indeterminate replay.

Added regression: Test_Ada_Generic_Abstract_State_Replay_Legality_Pass1227.
