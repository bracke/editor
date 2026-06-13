Editor Phase 579 — Pass906

This pass improves structural Ada grammar recovery for malformed raise statements at reserved statement-sequence boundaries.

Implemented:
- Added Production_Raise_Target_Reserved_Boundary_Recovery_Boundary.
- Refined raise-statement parsing so reserved boundary tokens after `raise` are not fabricated as exception-name targets.
- Preserved missing-exception-name recovery metadata, broader raise recovery metadata, valid following raise exception names, raise terminators, and generic recovery metadata.
- Added Test_Language_Model_Token_Cursor_Raise_Target_Reserved_Boundary_Recovery_Pass906.
- Updated validation/release guard notes and parser/colouring documentation.

This improves structural grammar coverage for malformed Ada raise targets at reserved statement-sequence boundaries. It is not compiler-grade exception-name legality checking, exception propagation legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
