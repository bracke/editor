# Editor pass732 — package declarative-item recovery depth

This pass improves structural Ada token-cursor recovery inside package
specifications and package bodies.  The goal is bounded grammar retention for
Outline and semantic-colouring metadata when package declarative regions contain
hostile or incomplete source, not compiler-grade legality checking.

Implemented changes:

* Added package declarative recovery boundary productions:
  * `Production_Package_Declarative_Recovery_Boundary`
  * `Production_Package_Unexpected_Begin_Boundary`
  * `Production_Package_Body_Unexpected_Private_Boundary`
* Replaced broad package declarative-item `is` depth handling with a
  package-aware synchronizer.
* Package recovery now resumes at strong declarative item starts after malformed
  declarations without relying on line ownership or rendering state.
* Package spec recovery now records premature `begin` as package recovery
  metadata instead of folding it into a preceding declaration.
* Package body recovery now records stray `private` before `begin` as recovery
  metadata and continues toward the body statement sequence.

Regression coverage:

* `Test_Language_Model_Token_Cursor_Package_Declarative_Item_Hostile_Recovery`

The regression covers malformed nested/private package contexts, missing
semicolons before following declarations, nested generic/package declarations,
representation clauses between declarations, premature `begin` in a package
spec, and unexpected `private` in a package body.

Non-goals:

* No compiler-grade package legality checking.
* No private-part conformance checking.
* No generic semantic expansion.
* No representation-clause freezing legality.
* No rendering-side parsing, LSP, compiler invocation, or external parser
  generator.
