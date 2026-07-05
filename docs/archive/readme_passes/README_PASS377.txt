Editor — IDE-grade Outline/Semantic Language Model — Pass 377

This pass extends executable-statement semantic binding with selected component
uses that occur inside executable expressions.

Implemented changes:
- Added parser-owned extraction of selected component uses from executable
  expressions, not only assignment targets.
- Added Add_Selected_Components_In_Expression in Editor.Ada_Declaration_Parser.
- Selected component bindings are now retained for condition expressions,
  actual expressions, assignment RHS expressions, and selected assignment
  targets.
- Declaration/visibility lines remain excluded from executable expression
  binding extraction.
- Selected calls remain call-target bindings rather than being duplicated as
  component-use bindings.
- Attribute-like contexts remain conservatively filtered.

Regression coverage:
- Test_Language_Model_Executable_Selected_Component_Uses

Still conservative:
- No full GNAT-equivalent executable statement legality checking.
- No full expression/name AST binding for every Ada statement form.
- Unknown or unresolved executable expressions still degrade to ordinary
  identifiers.
- No rendering-side parsing, external compiler integration, LSP integration,
  Python, shell scripts, or parser generators were added.
