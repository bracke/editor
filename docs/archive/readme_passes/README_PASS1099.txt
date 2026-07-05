Editor Pass1099

Pass1099 returns the phase to compiler-grade semantic progress instead of diagnostic projection churn.

This pass adds Editor.Ada_Assignment_Legality, a snapshot-owned Ada assignment and object-initialization legality building block.  It consumes expression type metadata, subtype compatibility, static expression metadata, type-graph-facing subtype names, and optional private/limited view compatibility metadata.  The package classifies assignment-like contexts without rendering-side parsing, file IO, dirty-state mutation, command/keybinding/workspace mutation, compiler invocation, external parsers, Python, or shell scripts.

The new legality classifications include compatible assignment, class-wide compatible assignment, static range compatible assignment, incompatible subtype, class-wide incompatible assignment, unresolved target subtype, unresolved source expression type, private-view barrier, limited-view barrier, cross-unit unresolved view, assignment to constant, assignment to in-mode formal, null-exclusion violation, static range violation, unresolved universal numeric assignment, and indeterminate legality.

The package preserves context identity, assignment kind, target/source nodes, source expression identity, target mode, target/source subtype text and normalized names, subtype compatibility status, view compatibility status, null-exclusion/class-wide/static-range metadata, source static value metadata, source span, fingerprints, deterministic counters, and lookup helpers.

Added AUnit regression package:

  Test_Ada_Assignment_Legality_Pass1099

The regression covers static in-range assignment acceptance, static range rejection, null-exclusion rejection, assignment to constants, assignment to in-mode formals, status lookups, context lookups, counters, and deterministic fingerprints.

This pass adds one compiler-grade building block for assignment and object-initialization legality. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
