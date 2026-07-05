Editor pass985 — representation legality static/freezing foundation

This pass adds one compiler-grade building block for Ada representation legality.
Full compiler-grade Ada analysis remains incomplete until the remaining layers
such as cross-unit semantic closure, complete freezing interactions, complete
record layout interpretation, full address-clause semantics, and full expression
type inference are fully integrated.

Implemented in pass985:

* Added Editor.Ada_Representation_Legality.
* Builds a deterministic representation-legality model from the parser-owned
  syntax tree, declarative regions, type graph, static-expression model, and
  freezing-point model.
* Stages each representation clause with target name, representation kind,
  item text, target freezable, target type/category, freeze-order status,
  static value status, source line, legality status, and fingerprint.
* Classifies representation clauses that appear after freezing separately from
  unresolved/ambiguous/non-freezable targets.
* Applies static-value checks for size, alignment, component size, object size,
  value size, storage size, machine radix, aft, and small clauses.
* Separates malformed static values, division by zero, non-static values, and
  non-positive values for positive-valued representation items.
* Adds first target-kind checks for record clauses, component size, small/aft,
  and machine radix using the type graph.
* Adds deterministic counters for ok checks, total errors, static errors,
  target-kind mismatches, and freezing-order errors.
* Added AUnit regression:
  Test_Ada_Representation_Legality_Static_Freezing_Pass985.

Remaining after pass985:

* Deeper record representation layout legality, including complete overlap and
  storage-unit interpretation through this new model.
* Enumeration representation clause completeness through the new legality API.
* Full address-clause static address semantics and System.Address compatibility.
* Operational attribute profile/type legality integration.
* Full private-view and freezing interactions for completions, generics, and
  representation items in separate compilation units.
