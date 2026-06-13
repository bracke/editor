Editor Phase 579 pass947
=========================

This pass adds a compiler-grade semantic foundation for Ada use-type primitive visibility.

Implemented:

* New package: Editor.Ada_Use_Type_Operators.
* Builds a deterministic, snapshot-owned model over:
  * Editor.Ada_Syntax_Tree
  * Editor.Ada_Declarative_Regions
  * Editor.Ada_Direct_Visibility
  * Editor.Ada_Use_Visibility
* Resolves use-type targets including selected type names such as P.T.
* Records primitive operator candidates made visible by use type clauses.
* Records primitive subprogram candidates made visible by use all type clauses.
* Adds stable IDs, owning regions, target type declarations, primitive declarations, source ranges, and fingerprints.
* Adds deterministic operator lookup over the primitive-use model.
* Adds AUnit coverage: Test_Ada_Use_Type_Operator_Visibility_Foundation_Pass947.

Scope:

This pass is a compiler-grade semantic building block for use-type operator visibility. Full compiler-grade Ada analysis still requires profile-aware primitive-operation filtering, expected-type propagation, overload resolution, type checking, static evaluation, generic contract checking, freezing/representation legality, and cross-unit semantic closure.
