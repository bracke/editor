Editor pass 216

This pass extends the parser-owned Ada language model with bounded default-expression metadata.

Implemented:
- Added Has_Default_Expression_Metadata to declaration flags.
- Included the flag in language-model fingerprints.
- Updated the declaration parser to detect sanitized := default/initializer syntax.
- Propagated the metadata to parsed declarations and generic formal object declarations.
- Updated Outline detail projection with default-expression metadata.
- Added Test_Language_Model_Default_Expression_Metadata.
- Extended language_validation_check for model/parser/test/docs markers.

The metadata is intentionally bounded: initializer/default expression contents do not become Outline rows, scope owners, or semantic declaration symbols.
