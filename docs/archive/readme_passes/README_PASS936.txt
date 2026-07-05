Editor pass936

This pass continues nr 6 rather than repeating pass935. It deepens subprogram contract/aspect grammar coverage by retaining contract-specific class-wide marks for Pre'Class and Post'Class, and by adding value-family metadata for Contract_Cases, Exceptional_Cases/Exit_Cases, Always_Terminates, Nonblocking, and Initializes/Depends-style aspects.

Changed code:
- src/core/editor-ada_token_cursor.ads
- src/core/editor-ada_token_cursor.adb
- tests/src/editor-syntax_semantics-tests.adb

New productions:
- Production_Classwide_Contract_Aspect_Mark
- Production_Contract_Cases_Aspect_Expression
- Production_Exceptional_Cases_Aspect_Expression
- Production_Always_Terminates_Aspect_Expression
- Production_Nonblocking_Aspect_Expression

New AUnit regression:
- Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Value_Families_Pass936

Scope:
This improves structural Ada grammar coverage for subprogram contract/aspect value families. It is not compiler-grade aspect legality checking, contract conformance checking, static-expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.
