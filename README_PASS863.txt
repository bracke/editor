Pass863 - Accept statement missing-entry-name recovery depth

Changed:
- Added `Production_Accept_Missing_Entry_Name_Recovery_Boundary`.
- Updated accept statement parsing so malformed/in-progress forms such as `accept ;` record accept-specific missing-entry-name recovery metadata instead of borrowing a following token as the entry name.
- Preserved well-formed accept entry-name, terminator, do-part, end-name, and missing-terminator metadata.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Accept_Entry_Name_Recovery_Pass863`.

This improves structural grammar coverage for Ada accept statement recovery. It is not compiler-grade accept statement legality checking, entry profile conformance, tasking legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
