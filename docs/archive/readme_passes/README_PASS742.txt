# Editor pass742

This pass deepens structural Ada token-cursor metadata for variant record component alternatives.

## Changed

* Added explicit variant-record productions for:
  * individual discrete variant choices,
  * range choices such as `A .. B`,
  * component declarations inside variant alternatives,
  * `null;` component alternatives.
* Kept nested variant parts explicit while retaining existing variant-part, choice-list, choice-separator, `others`, arrow, component-part, and recovery-boundary markers.
* Added AUnit regression:
  * `Test_Language_Model_Token_Cursor_Variant_Record_Component_Depth`
* Updated the  validation guard matrix so pass742 markers are required.

This improves structural grammar coverage for Ada variant record component alternatives. It is not compiler-grade discriminant legality checking, variant coverage checking, duplicate-choice legality checking, representation layout validation, or static-expression validation.
