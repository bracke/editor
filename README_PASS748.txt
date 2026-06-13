# Editor Phase 579 pass748

This pass deepens structural token-cursor coverage for Ada extended return
object declarations.

## Changed

* Extended return object declarations now retain explicit metadata for:
  * `aliased` return-object qualifiers;
  * `constant` return-object qualifiers;
  * return-object access definitions;
  * `not null` return-object null exclusions;
  * visibly constrained return-object subtype indications.
* Existing extended-return metadata remains in place for:
  * return-object defining names;
  * subtype indications;
  * initializers;
  * `do` parts;
  * `end return` synchronization.
* Added AUnit regression:
  * `Test_Language_Model_Token_Cursor_Extended_Return_Object_Qualifier_Depth`
* Updated validation guard markers.

This improves structural grammar coverage for Ada extended return object
declarations. It is not compiler-grade return-object legality checking,
accessibility checking, constant-object assignment checking, subtype constraint
validation, or function-result conformance checking.
