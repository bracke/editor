# Editor pass799 — Assignment statement terminator recovery depth

Pass799 deepens Ada assignment-statement terminator/recovery metadata.

Changed:
- Added token-cursor productions:
  - `Production_Assignment_Terminator`
  - `Production_Assignment_Missing_Terminator_Recovery_Boundary`
- Well-formed assignment statements now retain assignment-specific semicolon metadata:
  ```ada
  Value := Value + 1;
  ```
- Malformed or in-progress assignment statements that reach a body/select boundary without a visible semicolon now emit bounded assignment-specific recovery metadata:
  ```ada
  Value := Value + 2
  end Assignment_Terminator_Recovery;
  ```
- Preserved existing assignment metadata:
  - `Production_Assignment_Statement`
  - `Production_Assignment_Target`
  - `Production_Assignment_Selected_Target`
  - `Production_Assignment_Indexed_Target`
  - `Production_Assignment_Slice_Target`
  - `Production_Assignment_Dereference_Target`
  - `Production_Assignment_Target_Recovery_Boundary`
  - `Production_Assignment_Expression`
- Added AUnit regression:
  - `Test_Language_Model_Token_Cursor_Assignment_Terminator_Recovery_Pass799`
- Updated validation/release guards.
- Updated:
  - `README.md`
  - `README_PASS799.txt`
  - `docs/ada_parser_coverage_matrix.md`
  - `docs/release/RELEASE_CHECKLIST.md`
  - `tools/language_validation_check.adb`

This improves structural grammar coverage and bounded recovery for Ada assignment statements. It is not compiler-grade assignment legality checking, target writability checking, type compatibility checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
