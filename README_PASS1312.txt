Pass1312: Array/container/indexing vertical semantic slice.

Adds Editor.Ada_Array_Container_Indexing_Vertical_Slice_Legality.

This pass is a concrete vertical semantic slice, not diagnostic/provenance/recheck scaffolding.  It models array, container, and indexing legality with source-shaped rows and AUnit coverage.

Coverage includes:
- array type/object declaration index constraints;
- discrete index type requirements;
- index dimension/count checks;
- static out-of-bounds checks versus legal runtime bounds checks;
- unconstrained-array object constraint requirements;
- constrained-array constraint conflicts;
- array aggregate completeness, duplicate component, component type mismatch, named/positional mixing, and overlapping choices;
- array slicing range compatibility;
- generalized indexing profile presence and profile compatibility;
- container aggregate profile and element compatibility;
- container and parallel iterator element/shared-state checks;
- delta aggregate update target and component compatibility;
- private/limited view barriers;
- subtype/range, predicate, accessibility, initialization, and overload blockers;
- source, AST, type, and profile fingerprint freshness.

Added AUnit regression:
- Test_Ada_Array_Container_Indexing_Vertical_Slice_Legality_Pass1312
