Editor Pass 1034

This pass adds one compiler-grade building block for generic formal type
conformance. Full compiler-grade Ada analysis remains incomplete until the
remaining layers such as nested generic package actual contracts, generic
renaming, cross-unit semantic closure, and full overload/type checking are
fully integrated.

Implemented:

* Added Editor.Ada_Generic_Formal_Type_Conformance.
* Projects Editor.Ada_Generic_Contracts actual matching through
  Editor.Ada_Type_Graph.
* Stages deterministic conformance metadata for formal private, derived,
  interface, access, scalar/discrete, array, and record type contracts.
* Classifies compatible actuals, derived-compatible actuals,
  private-compatible actuals, interface-compatible actuals,
  access-compatible actuals, missing/unresolved actuals, category mismatches,
  base mismatches, private-view unknowns, and access designated-subtype
  unknowns.
* Exposes stable counters and deterministic fingerprints for diagnostics and
  semantic-colouring consumers.
* Added AUnit regression:
  Test_Ada_Generic_Formal_Type_Conformance_Pass1034.

Invariant notes:

* The model consumes parser-owned syntax-tree, generic-contract, and type-graph
  snapshots only.
* No rendering-side parsing is introduced.
* No file save/reload, dirty-state mutation, command-palette/keybinding,
  workspace, or render mutation path is introduced.
* All lookup and conformance records are deterministic and bounded by staged
  contract/type graph sizes.
