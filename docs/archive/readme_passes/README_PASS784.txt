# Editor Pass784

Pass784 adds bounded hostile-source recovery for generic formal package declarations.

Implemented changes:

- Added `Production_Formal_Package_Missing_Generic_Name`.
- Added `Production_Formal_Package_Missing_Generic_Recovery_Boundary`.
- Added `Production_Formal_Package_Actual_Missing_Arrow_Recovery_Boundary`.
- Formal package declarations missing the generic package name after `is new` now retain explicit recovery metadata, including forms such as `with package P is new (<>);` and `with package P is new;`.
- Formal package actual associations that look like named associations with an omitted `=>` now retain formal-package-specific missing-arrow recovery metadata while preserving conservative positional actual metadata.
- Incomplete actual lists before trailing generic-formal aspects continue to synchronize back to aspect parsing and following formal declarations.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Formal_Package_Hostile_Recovery_Pass784`.
- Updated validation and release guards.

Scope note:

This improves structural grammar coverage for hostile or in-progress Ada formal package declarations. It is not compiler-grade generic contract conformance, formal package matching, default availability checking, association legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
