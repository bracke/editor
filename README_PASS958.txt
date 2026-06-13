Editor Phase 579 - pass958

This pass continues the compiler-grade Ada semantic-analysis pivot after pass957.

Implemented:
- Extended Editor.Ada_Type_Graph with private/full-view metadata:
  - Type_View_Private_Partial
  - Type_View_Private_Full
  - Type_View_Private_Completion_Unresolved
  - Partial_View / Full_View links
- Added explicit interface type classification in the type graph.
- Added class-wide compatibility metadata:
  - Type_Compatibility_Class_Wide
  - Subtype_Compatibility_Type_Graph_Class_Wide
- Extended type-graph-aware expected-call filtering so an expected Root'Class context can accept a result whose type is Root or a declaration-derived descendant.
- Added AUnit regression:
  - Test_Ada_Type_Graph_Private_Classwide_Interface_Pass958

Scope:
This is a compiler-grade type-system building block for private-view completion metadata, interface classification, and class-wide expected-type compatibility. Remaining work includes full private-view visibility rules, interface operation conformance, full implicit conversions, complete overload resolution, static expression evaluation, generic contracts, freezing/representation legality, and cross-unit semantic closure.
