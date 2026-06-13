Pass813 - Package declaration end terminator recovery depth

This pass adds package-declaration-specific end/terminator metadata and bounded missing-terminator recovery.

Changed:
- Added Production_Package_Declaration_End_Keyword.
- Added Production_Package_Declaration_End_Name.
- Added Production_Package_Declaration_End_Terminator.
- Added Production_Package_Declaration_Missing_End_Terminator_Recovery_Boundary.
- Package declarations now retain visible end metadata for forms such as `end Package_Name;`.
- In-progress package declarations whose end line is missing a visible semicolon now retain bounded package-declaration-specific recovery metadata.
- Preserved existing package visible/private part and package declarative item recovery metadata.
- Added AUnit regression Test_Language_Model_Token_Cursor_Package_Declaration_End_Terminator_Pass813.
- Updated README, coverage matrix, release checklist, and phase579 validation guards.

This improves structural grammar coverage for Ada package declaration endings. It is not compiler-grade package/spec conformance checking, end-name matching, visibility analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
