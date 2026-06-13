Editor Phase 579 - Pass 721
===========================

Pass 721 improves Outline presentation precision for Ada type-family metadata
that earlier parser passes already retained structurally.

Changes
-------

- Added Outline label helpers for concrete type-family labels:
  - array type
  - access type
  - access subprogram type
  - derived type
  - private extension type
  - null extension type
  - interface type
  - tagged type
- Added matching generic formal type-family labels:
  - formal array type
  - formal access type
  - formal access subprogram type
  - formal derived type
  - formal private extension type
  - formal interface type
- Preserved existing detail metadata for filtering and inspection:
  - array
  - access
  - access-subprogram
  - derived
  - private-extension
  - null-record
  - interface/tagged modifiers
- Added AUnit coverage:
  - Test_Phase721_Ada_Outline_Type_Family_Label_Precision
- Updated the Phase 579 language validation guard to require the new helpers,
  labels, and regression coverage.

Scope
-----

This pass improves Outline presentation precision for parser-owned Ada
language-model metadata. It is not compiler-grade legality checking for type
derivation, access accessibility, array index legality, formal type matching,
private extension completion, interface implementation, visibility, freezing,
or expected-type analysis.
