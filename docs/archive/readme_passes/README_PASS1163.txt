Pass1163 -- Object-flow accessibility consumer legality

This pass adds one compiler-grade semantic consumer layer for exact accessibility scope evidence.

New package:
  Editor.Ada_Object_Flow_Accessibility_Consumer_Legality

Purpose:
  Feed Pass1162 exact accessibility-scope consumer results into concrete object-flow consumers so assignment, initialization, return, conversion, allocator, access-discriminant, aggregate, renaming, generic replay, and finalization legality cannot remain confidently legal when exact master/scope evidence is missing, mismatched, blocked, or indeterminate.

Semantic coverage:
  * assignment and object/component initialization object-flow acceptance
  * return object and return access lifetime checks
  * conversion, access conversion, and qualified expression lifetime checks
  * allocator master and designated subtype blockers
  * access discriminant master blockers
  * record/array aggregate discriminant and representation blockers
  * renaming dangling-risk blockers
  * generic actual and generic replay lifetime substitution blockers
  * finalization master blockers
  * preserved original object-flow errors
  * explicit missing/mismatched accessibility-consumer evidence rows

Regression:
  Test_Ada_Object_Flow_Accessibility_Consumer_Legality_Pass1163

This pass does not add UI/projection/status plumbing. It connects an existing semantic graph to real object-flow legality consumers.
