Pass1333 - Interfacing/import/export vertical legality slice

Implemented Editor.Ada_Interfacing_Import_Export_Vertical_Slice_Legality.

This pass adds a source-shaped legality engine for Ada interfacing constructs:
Convention, Import, Export, External_Name, Link_Name, address and storage
attributes, access-to-subprogram conventions, C-compatible profiles, and
representation conflicts between stream/external evidence.

The checker preserves blocker-family identity for missing evidence, entity-kind
mismatches, convention mismatches, disallowed conventions, import/export target
legality, non-static external/link names, address/static storage requirements,
storage-size incompatibility, C profile incompatibility, access-subprogram
profile/convention mismatches, import/export conflicts, duplicate interfacing
items, stream/external representation conflicts, view barriers, and stale
source/AST/entity/profile/representation fingerprints.

Added AUnit coverage in
Test_Ada_Interfacing_Import_Export_Vertical_Slice_Legality_Pass1333 and
registered it in Core_Suite.
