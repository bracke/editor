Editor — IDE-grade Outline / Semantic Colouring / Ada Parser
Pass895 — iterated component association missing-expression recovery

This pass continues the bounded Ada parser/token-cursor grammar coverage work
from pass894.

Implemented:

* Added Production_Iterated_Component_Missing_Expression_Recovery_Boundary.
* Added explicit boundary detection after an iterated component association
  arrow so separators, close delimiters, semicolons, and reserved recovery
  boundaries are not consumed as component expressions.
* Preserved Production_Iterated_Component_Association,
  Production_Iterated_Component_Association_Arrow, generic recovery metadata,
  and following declaration visibility.
* Added AUnit regression coverage in
  Test_Language_Model_Token_Cursor_Iterated_Component_Expression_Recovery_Pass895.
* Updated validation guards, parser coverage notes, syntax-colouring notes,
  release checklist, and README.

Representative malformed forms:

   (for I in 1 .. 3 =>)
   (for I in 1 .. 3 =>, 0)
   (for I in 1 .. 3 => when others => 0)

This improves structural grammar coverage for malformed Ada aggregate iterated
component associations. It is not expression type checking, aggregate legality
checking, iterator legality checking, overload resolution, compiler invocation,
LSP integration, render-side parsing, background whole-project scanning, or
dirty-state mutation.
