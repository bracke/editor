# Editor Phase 579 — Pass842

Selected-name missing-selector recovery depth.

Changes:
* Added Production_Selected_Name_Missing_Selector_Recovery_Boundary.
* Updated selected-name suffix parsing so dangling selected-name dots such as Root.Child. retain bounded missing-selector recovery metadata.
* Preserved existing selected-name prefix, separator, selector, literal-selector, operator-selector, and character-selector metadata.
* Added AUnit regression Test_Language_Model_Token_Cursor_Selected_Name_Missing_Selector_Recovery_Pass842.
* Updated parser coverage, syntax-colouring notes, release checklist, and validation guard markers.

Scope note:
This improves structural grammar coverage for Ada selected-name recovery. It is not compiler-grade name resolution, visibility analysis, selector legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
