Editor Phase 579 pass975
========================

This pass adds type-graph-aware generic formal subprogram profile conformance.

Implemented:
- Added Build_With_Type_Graph and Build_With_Static_And_Type_Graph to Editor.Ada_Generic_Contracts.
- Added profile subtype conformance checks backed by Editor.Ada_Type_Graph.
- Preserved conservative text-only Build behavior for existing callers.
- Added deterministic counters for type-compatible, type-mismatched, and type-unknown subprogram profile comparisons.
- Added AUnit regression Test_Ada_Generic_Formal_Subprogram_Type_Graph_Conformance_Pass975.

This is one compiler-grade building block. Full compiler-grade Ada analysis remains incomplete until the remaining semantic layers are fully integrated.
