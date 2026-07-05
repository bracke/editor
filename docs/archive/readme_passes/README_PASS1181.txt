Pass1181 - Integrated closure generic source/instance backmapping bridge

This pass adds Editor.Ada_Integrated_Semantic_Closure.Generic_Backmapping.

The new bridge consumes Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality rows and feeds them into integrated semantic closure without losing the generic body source, instantiation, formal, actual, substituted-body, replay-CPD, and overload/type-edge context captured by Pass1180.

Accepted generic backmap rows remain confident local closure rows. Non-legal rows are mapped to direct closure blocker families:

* missing source/instance/formal/actual/body nodes, missing maps, missing diagnostic backmaps, and fingerprint mismatches become coverage-gate blockers;
* generic replay flow blockers become dataflow blockers;
* predicate replay blockers become contract blockers;
* accessibility replay blockers become accessibility blockers;
* representation replay blockers become representation/freezing blockers;
* overload/type-edge blockers and ambiguities become overload blockers;
* indeterminate backmapping remains indeterminate integrated closure.

The pass adds Test_Ada_Integrated_Closure_Generic_Backmapping_Pass1181 and registers it in tests/src/core_suite.adb.

This pass adds one compiler-grade building block for generic replay closure fidelity. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
