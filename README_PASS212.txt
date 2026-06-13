Editor Phase 579 pass 212

This pass adds bounded parser/model metadata for Ada derived type declarations.

Changes:
- Added Has_Derived_Metadata to Editor.Ada_Language_Model.Declaration_Flags.
- Included derived metadata in deterministic language-model fingerprints.
- Updated Editor.Ada_Declaration_Parser so sanitized declarations containing Ada's derived-type `new` form retain derived metadata on the owning declaration.
- Updated Outline detail projection to show derived metadata.
- Added Test_Language_Model_Derived_Type_Metadata.
- Extended phase579_language_validation_check for derived metadata and regression coverage.
- Updated outline/syntax-colouring/release/README documentation.

The metadata is intentionally bounded: parent type expressions and the `new` keyword do not become standalone symbols, and no compiler-grade legality or inheritance analysis is attempted.
