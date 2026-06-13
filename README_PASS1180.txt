Pass1180 adds Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality.

This pass adds a compiler-grade building block for generic source/instance diagnostic backmapping. It preserves the two-sided mapping needed by instantiated generic-body semantic replay: the generic body source node where the rule is checked and the instantiation/formal/actual/substituted-body context that caused the replayed legality result.

The new package consumes generic instance body semantic replay, generic replay representation contract-predicate/dataflow consumer rows, and overload/type edge precision rows. A replay row cannot remain confidently legal unless the generic source node, instance node, formal node, actual node, substituted body node, source-instance map, formal-actual map, diagnostic backmap, source fingerprint, substitution fingerprint, replay CPD row, and overload/type edge row are all present and accepted.

The pass classifies missing generic source nodes, missing instance/formal/actual/body nodes, missing source-instance maps, missing formal-actual maps, missing diagnostic backmaps, fingerprint mismatches, base replay errors, missing or blocked replay CPD evidence, missing/blocked/ambiguous overload type-edge evidence, multiple matching replay CPD rows, multiple overload rows, and indeterminate states.

Added AUnit regression:
Test_Ada_Generic_Replay_Source_Instance_Backmapping_Legality_Pass1180

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
