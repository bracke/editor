Pass812 - Type/subtype declaration terminator recovery depth

This pass adds family-specific completion and bounded recovery metadata for Ada type and subtype declarations.

Changed:
- Added Production_Type_Declaration_Terminator.
- Added Production_Type_Declaration_Missing_Terminator_Recovery_Boundary.
- Added Production_Subtype_Declaration_Terminator.
- Added Production_Subtype_Declaration_Missing_Terminator_Recovery_Boundary.
- Type declarations now retain visible terminator metadata for full, incomplete, tagged-incomplete, private/aspect-bearing, scalar, array, access, derived, interface, and record-style declaration paths.
- Subtype declarations now retain visible terminator metadata after optional aspect specifications.
- In-progress type/subtype declarations now retain bounded missing-terminator recovery metadata instead of only relying on generic semicolon skipping.
- Added AUnit regression Test_Language_Model_Token_Cursor_Type_Subtype_Declaration_Terminator_Pass812.
- Updated README, coverage matrix, release checklist, and  validation guards.

This improves structural grammar coverage for Ada type/subtype declaration completion. It is not compiler-grade representation legality checking, subtype compatibility checking, aspect legality checking, static-expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
