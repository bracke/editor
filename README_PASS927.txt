Editor Phase 579 — IDE-grade Outline / Semantic Colouring / Ada Parser — Pass927

This pass improves structural grammar recovery for malformed Ada discriminant default expressions at reserved/aspect boundaries.

Changes:
- Added Production_Discriminant_Default_Reserved_Boundary_Recovery_Boundary.
- Refined discriminant specification default recovery so `D : Integer := with Volatile` and `D : Integer := then` do not fabricate boundary tokens as default expressions.
- Preserved discriminant specification metadata, shared profile-default reserved-boundary recovery metadata, generic recovery metadata, and valid following discriminant default-expression metadata.
- Added AUnit regression Test_Language_Model_Token_Cursor_Discriminant_Default_Reserved_Boundary_Recovery_Pass927.
- Updated validation guards, parser coverage notes, syntax-colouring notes, release checklist, and README.

Scope:
This improves structural grammar coverage for malformed Ada discriminant default expressions at reserved/aspect boundaries. It is not compiler-grade discriminant legality checking, default-expression type checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
