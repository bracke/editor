Editor pass773 — selected-name chain and dangling-selector grammar depth

This pass deepens name-grammar metadata for selected names without changing the
language-model architecture or introducing compiler-grade legality checks.

Changes:
- Added Production_Selected_Name_Separator.
- Added Production_Selected_Name_Chain_Component.
- Added Production_Selected_Name_Missing_Selector.
- Selected-name parsing now emits explicit dot boundary metadata, selector
  chain-component metadata for identifier, keyword, operator-symbol, and
  character-literal selectors, and selected-name-specific recovery metadata for
  dangling dots.
- Extended Test_Language_Model_Token_Cursor_Name_Grammar_Refinement_Completeness
  to cover separator retention, selector chain components, and dangling-selector
  recovery.
- Updated parser coverage, release guard, and validation guard notes.

This improves structural grammar coverage for Ada selected-name chains and
selected-name recovery. It is not compiler-grade name resolution, selected-name
legality checking, operator/character literal selector legality, overload
resolution, compiler invocation, LSP integration, render-side parsing, or dirty
state mutation.
