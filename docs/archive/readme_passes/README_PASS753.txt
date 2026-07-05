# Editor pass753 — label/goto metadata depth

Pass753 deepens structural Ada label and goto metadata in the token cursor.

## Changed

* Added label delimiter and recovery productions:
  * `Production_Label_Open_Delimiter`
  * `Production_Label_Close_Delimiter`
  * `Production_Label_Recovery_Boundary`
* Added goto terminator and label-name recovery productions:
  * `Production_Goto_Terminator`
  * `Production_Goto_Label_Recovery_Boundary`
* Explicit labels now retain the `<<` and `>>` boundaries separately from the
  label name.
* Empty or unterminated labels retain bounded recovery metadata.
* `goto` statements now retain their semicolon boundary when present.
* `goto` targets are treated structurally as label identifiers rather than
  general expression primaries; selected/indexed-looking tails keep a recovery
  marker and synchronize at the statement terminator.
* Added AUnit regression:
  * `Test_Language_Model_Token_Cursor_Label_Goto_Metadata_Depth`
* Updated validation guard markers and documentation.

## Scope

This improves structural grammar/model coverage for Ada labels and goto label
references. It is not compiler-grade goto legality checking, control-flow
analysis, reachability analysis, or accessibility validation.
