# Editor — pass754

This pass deepens block-statement declarative-part coverage in the Ada token cursor.

## Changed

* Added bounded token-cursor productions for block-statement internals:
  * `Production_Block_Declare_Keyword`
  * `Production_Block_Declarative_Begin_Boundary`
  * `Production_Block_Declarative_Item_Start`
  * `Production_Block_Declarative_Item_Recovery_Boundary`
  * `Production_Block_Exception_Keyword`
  * `Production_Block_Label_Name`
* Named block labels such as `Local_Block : declare` now retain block-specific label metadata in addition to the existing statement-identifier metadata.
* Declare blocks now retain explicit declarative-item start and `begin` boundary markers.
* Block exception parts now retain an explicit exception-keyword marker in addition to the existing exception-part/handler metadata.
* Extended AUnit coverage in `Test_Language_Model_Token_Cursor_Block_Statement_Grammar_Completeness`.
* Updated release/validation guards and documentation.

## Non-goals

This is structural grammar metadata only. It is not compiler-grade block legality checking, declaration legality checking, exception propagation analysis, visibility checking, or control-flow analysis.
