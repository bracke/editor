Editor Pass1100

Pass1100 adds one compiler-grade semantic building block for Ada return statement legality.

Implemented:

  Editor.Ada_Return_Legality

The new package consumes Editor.Ada_Assignment_Legality and projects snapshot-owned return contexts into deterministic return-legality rows.  It classifies procedure returns without expressions, function returns with compatible result expressions, extended return object compatibility, procedure returns with illegal expressions, function returns missing expressions, result subtype incompatibility, class-wide incompatibility, private/limited view barriers, cross-unit unresolved views, unresolved target/source result metadata, static range violations, unresolved universal numeric returns, No_Return subprogram return statements, and indeterminate cases.

Regression coverage:

  Test_Ada_Return_Legality_Pass1100

The pass also registers the Pass1099 and Pass1100 semantic regressions in Core_Suite when that suite is used as the AUnit entry point.

No rendering-side parsing, file save/reload, dirty-state mutation, command-palette/keybinding/workspace/render mutation, compiler invocation, LSP, external parser generator, Python script, or shell script is introduced into the project.
