Editor Phase 579 Pass873
========================

Pass873 continues from pass872 and improves structural Ada token-cursor grammar coverage for formal package declarations. The parser now records Production_Formal_Package_Actual_Empty_Recovery_Boundary when a formal package actual part is written as an empty parenthesized list, for example:

   with package P is new G ();

Ada formal package actual parts are either the dedicated box form (<>) or contain one or more generic actual associations. The new metadata distinguishes malformed empty lists from omitted/defaulted actual parts and from valid whole-part box defaults while preserving the close delimiter and allowing recovery to continue at following generic formal declarations.

AUnit coverage is provided by Test_Language_Model_Token_Cursor_Formal_Package_Empty_Actual_Recovery_Pass873.

This improves structural grammar coverage for empty formal package actual-list recovery. It is not compiler-grade generic contract legality checking, actual/default legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
