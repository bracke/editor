Pass1102 - Wide control-flow and statement legality semantic block

This pass adds Editor.Ada_Control_Flow_Legality as a compiler-grade building
block for Ada statement/control-flow legality.  It deliberately returns to core
semantics instead of extending the diagnostic UI projection chain.

The package consumes Editor.Ada_Return_Legality and fixture-provided resolved
statement facts.  It classifies Boolean-only conditions, case expression and
choice legality, exit/goto/label target legality, exception handler choices,
raise statement exception resolution, select/accept/requeue target checks, and
subprogram return-path completeness.

The model is deterministic, bounded, and snapshot-owned.  It performs no
render-side parsing, file IO, buffer dirty-state mutation, command-palette or
keybinding mutation, workspace/session mutation, or render mutation.

Added regression:

  Test_Ada_Control_Flow_Legality_Pass1102

Registered in:

  tests/src/core_suite.adb

This pass adds one compiler-grade building block for Ada control-flow and
statement legality.  Full compiler-grade Ada analysis remains incomplete until
remaining overload resolution, type checking, generic contracts,
freezing/representation legality, accessibility/lifetime rules, tasking and
protected semantics, and cross-unit semantic closure are fully integrated.
