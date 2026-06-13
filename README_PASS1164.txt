Pass1164 -- Definite-initialization object-flow consumer legality

This pass adds one compiler-grade semantic consumer layer for definite-initialization and flow-sensitive object-state legality.

New package:
  Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality

Purpose:
  Feed Pass1163 object-flow accessibility consumer results into definite-initialization flow legality so initialization, read-before-write, out-parameter, return-object, component, aggregate, exception-path, finalization, and generic replay conclusions cannot remain confidently legal when exact object-flow/lifetime evidence is missing, mismatched, blocked, or indeterminate.

Semantic coverage:
  * object and component initialization acceptance gated by object-flow evidence
  * assignment and return initialization gated by exact lifetime/object-flow evidence
  * aggregate initialization gated by discriminant/variant and representation blockers
  * finalization-path initialization gated by finalization master/lifetime evidence
  * read-before-write and partial-initialization errors preserved as original initialization failures
  * missing object-flow evidence and mismatched consumer-kind evidence are explicit blockers
  * indeterminate initialization or object-flow evidence remains indeterminate instead of becoming confident

Regression:
  Test_Ada_Definite_Initialization_Object_Flow_Consumer_Legality_Pass1164

This pass does not add UI/projection/status plumbing. It connects existing object-flow and accessibility semantics to real definite-initialization consumers.
