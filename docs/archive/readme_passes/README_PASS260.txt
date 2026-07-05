Editor pass 260

This pass extends parser-owned Ada statement awareness for ordinary return-expression statements.

Implemented:
- Added Statement_Return_With_Expression.
- Added Statement_Alternative_Return_With_Expression.
- Parser now distinguishes bare returns from ordinary expression returns:
    return;
    return Value + 1;
- Parser now preserves return-expression actions after executable alternative arrows:
    when C => return Value + 1;
- Extended return objects remain separate and are not flattened into ordinary return-expression metadata:
    return Result : Item := Default_Item;
    return Result : Item do ... end return;
- The metadata remains bounded parser-owned analysis data only. It creates no Outline rows, semantic symbols, scopes, declarations, or navigation targets.

Updated:
- src/core/editor-ada_language_model.ads
- src/core/editor-ada_declaration_parser.adb
- tests/src/editor-syntax_semantics-tests.adb
- tools/language_validation_check.adb
- README.md
- docs/outline.md
- docs/syntax_colouring.md
- docs/release/RELEASE_CHECKLIST.md
