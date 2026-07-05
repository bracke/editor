Editor pass1016

This pass adds one compiler-grade building block for aggregate expression type analysis. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Implemented:

- Extended Editor.Ada_Expression_Types with type-graph-aware aggregate validation metadata.
- Record aggregate validation now stages compatible component associations, missing component associations, and duplicate component associations when the expected record type and component declarations are available from the parser-owned syntax tree/type graph.
- Array aggregate validation now stages compatible element associations, element mismatches, and unknown element checks from the expected array/string element subtype context.
- Aggregate mismatch and unknown counters now include the deeper record/array validation statuses.
- Aggregate validation metadata participates in deterministic expression-type fingerprints.
- Added AUnit regression Test_Ada_Expression_Aggregate_Type_Graph_Validation_Pass1016.

Invariants preserved:

- No rendering-side parsing.
- No file saves/reloads during analysis.
- No dirty-state mutation.
- No command-palette/keybinding/workspace/render mutation leaks.
- Analysis remains deterministic, bounded, and snapshot-owned.
- No LSP, compiler invocation, external parser generators, Python, or shell scripts were added to the project.
