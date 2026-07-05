Pass1113 - Wide Ada elaboration/dependence legality

This pass adds Editor.Ada_Elaboration_Dependence_Legality, a snapshot-owned Ada elaboration-order and semantic-dependence legality layer.

The pass covers Elaborate, Elaborate_All, Elaborate_Body, Preelaborate, Pure, Remote_Types, Shared_Passive, call/access-before-elaboration, body-before-use, generic instance elaboration, circular elaboration dependencies, missing or ambiguous dependencies, and linked blockers from cross-unit closure, contract/aspect legality, and overload legality.

The package remains deterministic and bounded. It performs no parsing, file IO, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, or external analysis.

AUnit coverage added:
  Test_Ada_Elaboration_Dependence_Legality_Pass1113

This pass adds one compiler-grade building block for elaboration/dependence legality. Full compiler-grade Ada analysis remains incomplete until the remaining semantic layers are fully integrated and validated end-to-end.
