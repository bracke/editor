Pass814 - Formal package actual-part delimiter depth

This pass adds formal-package-specific delimiter and separator metadata for generic formal package actual parts.

Changed:
- Added Production_Formal_Package_Actual_Part_Open_Delimiter.
- Added Production_Formal_Package_Actual_Part_Close_Delimiter.
- Added Production_Formal_Package_Actual_Association_Separator.
- Added Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary.
- `with package P is new G (<>);` now retains formal-package actual-part open and close delimiter metadata.
- Named and positional formal package actual lists now retain comma separator metadata.
- In-progress formal package actual parts ending at semicolon before a matching close delimiter now retain bounded missing-close recovery metadata.
- Added AUnit regression Test_Language_Model_Token_Cursor_Formal_Package_Actual_Delimiters_Pass814.
- Updated README, coverage matrix, release checklist, and phase579 validation guards.

This improves structural grammar coverage for Ada generic formal package actual parts. It is not compiler-grade generic contract conformance, formal package matching, association legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
