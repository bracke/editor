Editor Phase 579 pass1033
=========================

Implemented aspect inheritance and overriding rules.

New package:

* Editor.Ada_Aspect_Inheritance_Rules

Scope:

* Consumes Editor.Ada_Representation_Legality after aspect vs
  attribute-definition unification.
* Consumes Editor.Ada_Type_Graph derived/private/full-view relationships.
* Stages inherited representation/operational properties for derived types.
* Distinguishes explicit same-value overrides from contradictory explicit
  overrides.
* Preserves private partial-view and private full-view override metadata when
  exposed by the type graph.
* Exposes deterministic counters and fingerprints for later diagnostics and
  semantic-colouring projection.

Public counters:

* Inherited_Count
* Override_Count
* Conflict_Count
* Private_View_Count
* Unknown_Count
* Fingerprint

Regression:

* Test_Ada_Aspect_Inheritance_Override_Rules_Pass1033

This pass adds one compiler-grade building block for aspect and representation
legality. Full compiler-grade Ada analysis remains incomplete until overload
resolution, type checking, generic contracts, freezing/representation legality,
and cross-unit semantic closure are fully integrated.
