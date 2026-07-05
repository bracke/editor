Editor pass964

Implemented compiler-grade static-expression real/universal numeric foundation.

Changes:
- Extended Editor.Ada_Static_Expressions with Static_Value_Real and Real_Value metadata.
- Added Evaluate_Numeric_Expression for deterministic integer/real static arithmetic staging.
- Kept Evaluate_Integer_Expression integer-only by explicitly rejecting real-valued expressions as non-static in integer-only contexts.
- Added decimal and exponent literal support, named real constant references, real unary +/- and +, -, *, / arithmetic.
- Preserved real division by zero as explicit diagnostic metadata.
- Added Is_Static_Real and Is_Static_Numeric predicates.
- Added AUnit regression Test_Ada_Static_Real_Numeric_Foundation_Pass964.
- Updated parser coverage docs, syntax-colouring notes, release checklist, strict runtime validation record, and README.

Scope:
This pass is a compiler-grade static-expression building block for real/universal numeric arithmetic. It does not complete Ada real-type legality, fixed-point static evaluation, universal numeric resolution in all contexts, static attribute completeness, generic contracts, freezing/representation legality, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.
