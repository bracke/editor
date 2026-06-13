Editor Phase 579 pass767 — pragma argument association depth

This pass deepens token-cursor grammar for pragma argument associations.

Implemented:
- Added Production_Pragma_Argument_Named_Association.
- Added Production_Pragma_Argument_Positional_Association.
- Added Production_Pragma_Argument_Box for <> pragma arguments.
- Kept existing Production_Pragma_Argument_Association and Production_Pragma_Argument_Expression for compatibility.
- Added AUnit regression coverage for mixed positional, named, box, and nullary pragmas.

This improves structural grammar coverage for pragma argument lists. It is not compiler-grade pragma legality checking, implementation-defined pragma semantics, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
