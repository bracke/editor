# Editor Phase 579 pass727 — Use-clause metadata projection

This pass deepens the existing use-clause grammar support by projecting
individual use-clause names into language-model visibility metadata.

Implemented changes:

- Added `Use_Clause_Count` and `Use_Clause_At` convenience accessors to
  `Editor.Ada_Language_Model` so resolver/index/colouring consumers can inspect
  only retained use-clause entries without manually filtering all visibility
  clauses.
- Kept ordinary `use P, Q;`, `use type T, U;`, and `use all type T, U;`
  entries distinct as `Visibility_Use_Package_Clause`,
  `Visibility_Use_Type_Clause`, and `Visibility_Use_All_Type_Clause`.
- Tightened comma-separated visibility-name range projection so each retained
  use-clause name receives its own source-column range instead of reusing the
  first name's base column.
- Added AUnit coverage for selected package names, selected subtype marks, and
  class-wide `use all type` names projected as individual language-model
  metadata rows.
- Updated the phase validation guard to require the new use-clause projection
  accessors and precise visibility-name range path.

This improves structural grammar coverage and language-model projection for Ada
use clauses. It is not compiler-grade visibility, overload, or legality checking.
