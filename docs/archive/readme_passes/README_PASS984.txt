Pass984 — freezing-point model foundation

Added Editor.Ada_Freezing_Points.

The new model derives deterministic freezable declaration metadata from parser-owned syntax, declarative regions, direct visibility, and the type graph. It records first conservative freezing causes and source lines, including object declarations that freeze their subtype mark and subprogram bodies that freeze matching subprogram declarations.

Representation clauses are now staged with freeze-order metadata. Consumers can distinguish representation clauses before the first freeze point, at the freeze point, after the freeze point, not-yet-frozen targets, unresolved targets, and non-freezable targets.

Added AUnit regression:
Test_Ada_Freezing_Point_Foundation_Pass984

This pass adds one compiler-grade building block for freezing and representation legality. Full compiler-grade Ada analysis remains incomplete until the remaining representation/operational legality, private-view, overload-resolution, generic-body, and cross-unit semantic layers consume this model.
