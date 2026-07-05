Editor pass1031
==========================

This pass adds one compiler-grade building block for record representation
layout semantics: Bit_Order / Scalar_Storage_Order interaction metadata for
record component clauses. Full compiler-grade Ada analysis remains incomplete
until the remaining layers such as overload resolution, type checking, generic
contracts, freezing/representation legality, and cross-unit semantic closure
are fully integrated.

Implemented
-----------

* Added Editor.Ada_Record_Storage_Order_Rules.
* Consumes Editor.Ada_Representation_Legality and
  Editor.Ada_Record_Layout_Validation without reparsing source or performing
  file IO.
* Projects explicit Bit_Order and Scalar_Storage_Order clauses onto staged
  record component layout spans.
* Classifies component clauses as:
  - no explicit order,
  - Bit_Order applied,
  - Scalar_Storage_Order applied,
  - both order attributes applied,
  - conflicting order metadata,
  - operational order/value error,
  - upstream layout error,
  - unknown.
* Preserves source nodes, target/component names, order clause nodes, order
  values, source lines, and deterministic fingerprints.
* Added deterministic counters for explicit-order components, Bit_Order
  components, Scalar_Storage_Order components, conflicts, operational errors,
  layout errors, unknowns, and aggregate fingerprinting.
* Added AUnit regression:
  Test_Ada_Record_Storage_Order_Interaction_Pass1031.

Invariant notes
---------------

* No rendering-side parsing.
* No file saves/reloads during analysis.
* No dirty-state mutation.
* No command-palette/keybinding/workspace/render mutation leaks.
* Analysis remains deterministic, bounded, and snapshot-owned.
* The new package is projection metadata only; diagnostics/colouring consumers
  can use it later without mutating parser or render state.
