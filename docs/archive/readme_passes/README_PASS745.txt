# Editor — Pass745

Pass745 deepens generic formal type detail projection in the Ada language model.

## Implemented

* Added bounded language-model metadata for generic formal type declarations.
* Added family classification for:
  * formal private types
  * formal derived types
  * formal discrete types
  * formal signed integer types
  * formal modular integer types
  * formal floating point types
  * formal ordinary fixed point types
  * formal decimal fixed point types
  * formal array types
  * formal access-object types
  * formal access-to-subprogram types
  * formal interface types
* Added retained target/profile detail for formal type families where useful:
  * derived parent subtype mark
  * array element subtype mark
  * access designated subtype mark
  * access-to-subprogram profile summary
  * interface parent subtype mark
* Added accessors:
  * `Add_Generic_Formal_Type_Metadata`
  * `Generic_Formal_Type_Metadata_Count`
  * `Generic_Formal_Type_Metadata_At`
* Added AUnit regression:
  * `Test_Language_Model_Generic_Formal_Type_Detail_Metadata`
* Updated validation guard markers for pass745.

## Non-goals

This improves structural grammar/model coverage for Ada generic formal type declarations. It is not compiler-grade generic conformance checking, formal type matching, static-expression validation, private extension legality checking, or full generic semantic expansion.
