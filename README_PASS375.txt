Pass 375 - executable-statement semantic binding

This pass adds bounded executable-statement semantic bindings to the Ada language model.

Implemented:
- New Editor.Ada_Language_Model executable binding metadata:
  - loop parameters
  - declare/block-local object declarations
  - exception handler choices
  - assignment targets
  - call targets
  - selected assignment components
  - statement label declarations
  - goto targets
- Parser-owned extraction from immutable text snapshots after declaration/syntax-tree projection.
- Bindings retain source spelling, normalized name, source range, lexical scope, expression text, and an optional resolved target symbol.
- Editor.Syntax_Semantics.Build_Map_From_Analysis consumes safe executable bindings so semantic colouring can classify statement-local/value-like names where the model has enough information.
- Added AUnit coverage: Test_Language_Model_Executable_Statement_Bindings.

Conservative limits:
- No compiler-grade statement legality checking.
- No full expression/name AST binding for every executable statement form.
- Unknown or unresolved statement expressions remain ordinary identifiers.
- No rendering-side parsing, external compiler integration, LSP integration, Python, shell scripts, or parser generators.
