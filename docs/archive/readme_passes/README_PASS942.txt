Editor pass942

Compiler-grade grammar foundation pass for Ada 2022 expression syntax-tree coverage.

Implemented:
- Added syntax-tree node kinds for Ada 2022 grammar families that were already token-cursor visible but not yet retained as expression-tree nodes:
  - Node_Declare_Expression
  - Node_Delta_Aggregate
  - Node_Container_Aggregate
  - Node_Reduction_Expression
  - Node_Iterator_Specification
  - Node_Target_Name
- Extended expression-node attachment so declaration defaults now produce expression children, allowing object/constant declarations to retain nested Ada 2022 expression grammar metadata.
- Added detection for declare expressions, delta aggregates with target-name @ usage, container aggregates with iterator specifications, and Reduce/Parallel_Reduce/Map_Reduce expression forms.
- Added AUnit coverage in Test_Ada_Syntax_Tree_Ada2022_Expression_Node_Coverage_Pass942.
- Updated parser coverage docs, syntax-colouring docs, release checklist, README, and validation guard markers.

Compiler-grade scope:
This is one compiler-grade grammar-model building block: these Ada 2022 constructs now have stable syntax-tree node families that semantic analysis can consume without reparsing raw text. Full compiler-grade Ada analysis still requires the remaining semantic layers: complete name resolution, overload resolution, type checking, static evaluation, generic contract checking, freezing/representation legality, and cross-unit semantic consistency.
