Pass1179 adds Editor.Ada_Overload_Type_Edge_Precision_Legality.

This pass adds one compiler-grade building block for Ada overload and type-resolution edge cases. It consumes Pass1141 RM overload edge legality, Pass1178 expression construct AST repair legality, and Pass1171 generic replay representation contract-predicate/dataflow evidence. Access-to-subprogram overloads, universal fixed/root numeric choices, inherited primitive hiding, dispatching/nondispatching selection, generic formal subprograms, nested generic calls, and class-wide controlling-operation contexts cannot remain confidently legal when the required repaired expression AST or generic replay evidence is missing, blocked, or indeterminate.

The new AUnit regression is Test_Ada_Overload_Type_Edge_Precision_Legality_Pass1179 and is registered in tests/src/core_suite.adb.

Full compiler-grade Ada analysis remains incomplete until remaining Ada legality, overload/type resolution, generic replay source mapping, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST repair, and cross-unit semantic closure layers are fully integrated.
