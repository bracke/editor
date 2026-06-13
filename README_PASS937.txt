Editor Phase 579 pass937

This pass improves structural Ada grammar coverage for package specification/body declarative section recovery.

Implemented:
- Added token-cursor production `Production_Package_Duplicate_Private_Boundary` for duplicate `private` markers in package specifications.
- Added token-cursor production `Production_Package_Private_Begin_Recovery_Boundary` for `begin` reached from a package private part.
- Added token-cursor production `Production_Package_Body_Private_Declarative_Recovery_Boundary` for illegal `private` markers in package body declarative parts.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Package_Declarative_Section_Recovery_Depth_Pass937`.
- Updated parser coverage docs, syntax-colouring notes, release checklist, validation guards, and README.

Scope:
- This improves structural grammar coverage for malformed package visible/private/body transitions.
- It is not compiler-grade package legality checking, declarative-part legality checking, visibility checking, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.
