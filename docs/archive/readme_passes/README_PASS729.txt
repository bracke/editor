# Editor pass729 — Pragma placement metadata projection

This pass deepens Ada pragma structural coverage in the language model without
changing the editor architecture.

Implemented:

* Added bounded pragma metadata records to `Editor.Ada_Language_Model`.
* Added `Pragma_Placement_Kind` to distinguish configuration, declarative,
  statement, and alternative pragmas.
* Added `Add_Pragma_Metadata`, `Pragma_Metadata_Count`, and
  `Pragma_Metadata_At` accessors.
* Projected syntax-tree pragma nodes into the language model with:
  * pragma identifier,
  * placement class,
  * enclosing scope,
  * first entity/argument target text,
  * total argument count,
  * named argument association count,
  * retained source range.
* Kept pragma identifiers and pragma arguments as metadata only; they do not
  become outline declarations or resolver symbols.
* Added AUnit regression coverage via
  `Test_Language_Model_Pragma_Placement_And_Target_Metadata`.
* Updated phase validation guards and user-facing parser/colouring docs.

This improves structural grammar/model coverage for pragma placement and
pragma argument metadata. It is not compiler-grade pragma legality checking,
configuration-pragmas partition validation, or implementation-defined pragma
semantics.
