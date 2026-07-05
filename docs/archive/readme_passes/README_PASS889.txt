Editor Pass889 — Name/attribute prefix and incomplete selected-name refinement

This pass improves structural Ada grammar coverage for name grammar refinements
around attribute references and incomplete selected subtype marks.

Changes:

* Added Production_Attribute_Selected_Prefix.
* Added Production_Attribute_Complex_Prefix.
* Added Production_Qualified_Expression_Incomplete_Selected_Subtype_Mark.
* Added Production_Allocator_Incomplete_Selected_Subtype_Mark.
* Attribute references whose prefixes contain selected-name components now
  retain selected/complex prefix metadata for semantic-colouring and resolver
  consumers.
* Qualified-expression contexts such as Broken.'(1) now retain
  qualified-expression-specific incomplete selected subtype-mark recovery.
* Allocator subtype indications such as new Broken.; now retain
  allocator-specific incomplete selected subtype-mark recovery.
* Existing selected-name missing-selector recovery and following declaration
  visibility are preserved.

Regression:

* Test_Language_Model_Token_Cursor_Name_Attribute_Refinement_Pass889

This improves structural grammar coverage only. It is not attribute legality
checking, subtype legality checking, overload resolution, compiler invocation,
LSP integration, render-side parsing, background whole-project scanning, or
dirty-state mutation.
