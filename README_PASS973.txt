Phase 579 pass973 — Generic default-expression legality foundation

This pass adds one compiler-grade building block for generic object formal conformance.  `Editor.Ada_Generic_Contracts` can now be built with the static-expression model and classify defaulted formal-object expressions and explicit object actual expressions as static, illegal, or unresolved/unknown.

Implemented changes:

* Added `Build_With_Static` so callers that have `Editor.Ada_Static_Expressions.Static_Model` can request stricter generic default-expression checks without changing legacy `Build` behaviour.
* Added formal-object expression legality metadata to `Generic_Actual_Match_Info`:
  - checked object expressions
  - static object expressions
  - illegal object expressions
  - unknown/unresolved object expressions
  - non-static, malformed, and division-by-zero detail counters
* Added statuses:
  - `Generic_Actual_Match_Formal_Object_Default_Illegal`
  - `Generic_Actual_Match_Formal_Object_Default_Unknown`
* Added public deterministic counters:
  - `Default_Expression_Static_Count_For_Instance`
  - `Default_Expression_Illegal_Count_For_Instance`
  - `Default_Expression_Unknown_Count_For_Instance`
* Preserved default text from formal object declaration labels when the syntax-tree default child is unavailable.
* Added AUnit regression `Test_Ada_Generic_Default_Expression_Legality_Pass973`.

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as private-view visibility rules, freezing, representation legality, cross-unit semantic closure, full expression type inference, and complete profile conformance are fully integrated.
