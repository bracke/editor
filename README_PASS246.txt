Editor Phase 579 Pass 246
=========================

Focus
-----
Continued parser gap nr 1 by extending parser-owned statement-awareness metadata to Ada extended return statements.

Implemented
-----------
- Added Statement_Extended_Return to Editor.Ada_Language_Model.Statement_Kind.
- Added Statement_End_Return to Editor.Ada_Language_Model.Statement_Kind.
- Parser now recognizes extended return statements such as:
    return Result : Item do
       Initialize (Result);
    end return;
- Parser also recognizes initialized extended returns such as:
    return Result : Item := Default_Item;
- Structured end-return terminators are retained as statement metadata.
- Extended returns continue to count as ordinary return statements as well.
- Return statement metadata does not create Outline rows or semantic declaration symbols.
- Added AUnit coverage for do/end-return and initialized extended returns.
- Extended phase579_language_validation_check.
- Updated README and language-feature documentation.

Scope note
----------
This remains bounded statement-awareness metadata, not a full Ada statement AST or expression parser.
