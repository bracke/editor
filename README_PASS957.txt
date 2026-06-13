Editor Phase 579 — Pass957

Implemented declaration-derived type-graph compatibility integration for expected-call filtering.

Changes:
- Extended Editor.Ada_Subtype_Compatibility with type-graph-aware compatibility statuses and Check_With_Type_Graph.
- Extended Editor.Ada_Expected_Call_Filters with Type_Compatibility metadata and Build_With_Type_Graph.
- Expected-call filtering can now accept declaration-derived and subtype result compatibility instead of falling back to normalized subtype text equality or indeterminate user-defined relationships.
- Known different type roots are retained as mismatch metadata for diagnostics.
- Added AUnit regression Test_Ada_Expected_Call_Filter_Type_Graph_Compatibility_Pass957.

Scope:
This is a compiler-grade type-checking and overload-resolution building block. Full compiler-grade Ada analysis still requires private-view completion, class-wide/interface compatibility, implicit conversions, static expression evaluation, generic contracts, freezing/representation legality, and cross-unit semantic closure.
