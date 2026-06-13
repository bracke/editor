Editor Phase 579 - Pass1129

Pass1129 adds Editor.Ada_Elaboration_Precision_Legality.

This pass deepens elaboration/dependence legality beyond the Pass1113 broad classifier by connecting:

- elaboration-order graph closure,
- body-before-use and Elaborate_Body requirements,
- Elaborate_All dependency closure,
- call-before-body elaboration risks,
- access-before-elaboration risks,
- generic instance body elaboration,
- preelaboration, Pure, Remote_Types, and Shared_Passive restrictions,
- Global/Depends dataflow errors during elaboration,
- overload preference failures on calls during elaboration,
- accessibility precision risks for access values used during elaboration,
- linked errors from the existing elaboration, generic-body, dataflow, overload-preference, and accessibility precision layers.

The new package is snapshot-owned, deterministic, parser-free, projection-free, and side-effect-free. It performs no rendering-side parsing, file IO, dirty-state mutation, command registration, workspace mutation, compiler invocation, or external parser invocation.

AUnit coverage was added in Test_Ada_Elaboration_Precision_Legality_Pass1129 and registered in tests/src/core_suite.adb. The regression verifies legal dependency ordering, call-before-body elaboration, access-before-elaboration, generic instance body elaboration, missing Elaborate_All, graph cycles, preelaboration/purity restrictions, dataflow read-before-write during elaboration, overload preference blockers, accessibility risks, linked generic body blockers, lookups, counters, and deterministic fingerprints.

This pass adds one compiler-grade building block for elaboration/dependence precision. Full compiler-grade Ada analysis remains incomplete until remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
