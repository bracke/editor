# Editor Pass850 — Exit-when condition recovery depth

Pass850 improves structural grammar coverage for Ada `exit when` statements by adding
`Production_Exit_When_Missing_Condition_Recovery_Boundary` when a `when` keyword is
followed immediately by a statement/declaration synchronization boundary rather than a
condition expression.

The pass keeps normal `exit when Ready;` condition metadata intact and records bounded
recovery for malformed/in-progress forms such as `exit when;`, while preserving the
statement terminator and following statements for Outline, diagnostics, and semantic
colouring consumers.

This is parser/token-cursor structural metadata only. It is not compiler-grade loop
legality checking, condition type checking, overload resolution, compiler invocation,
LSP integration, render-side parsing, or dirty-state mutation.
