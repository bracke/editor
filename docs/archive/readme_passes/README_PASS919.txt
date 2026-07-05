Editor — IDE-grade Outline / Semantic Colouring / Ada Parser — Pass919

This pass improves structural Ada grammar recovery for malformed object initialization expressions at reserved or aspect/declaration boundaries.

Implemented changes:

* Added Production_Object_Initialization_Reserved_Boundary_Recovery_Boundary.
* Refined object declaration initializer parsing so `:=` followed by `with`, `end`, `else`, `elsif`, `exception`, `then`, `when`, `do`, `;`, `,`, or `)` records object-initializer-specific recovery metadata instead of treating the boundary token as an initializer expression.
* Preserved object declaration metadata, object initialization metadata, broader object-declaration recovery metadata, generic recovery metadata, and following valid declarations.
* Added AUnit regression coverage in Test_Language_Model_Token_Cursor_Object_Initialization_Reserved_Boundary_Recovery_Pass919.
* Updated validation guard comments, parser coverage documentation, syntax-colouring notes, release checklist, and README.

This improves structural grammar coverage for malformed Ada object initialization expressions. It is not compiler-grade object declaration legality checking, initializer type checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
