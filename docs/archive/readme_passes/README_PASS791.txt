Editor pass791 - terminate alternative terminator recovery depth

This pass deepens Ada token-cursor coverage for select terminate alternatives.

Implemented:
- Added Production_Terminate_Terminator.
- Added Production_Terminate_Missing_Terminator_Recovery_Boundary.
- Well-formed terminate alternatives now retain a terminate-specific semicolon marker.
- Malformed or in-progress terminate alternatives without a visible semicolon now emit bounded recovery metadata and a parser-owned recovery point.
- Added AUnit regression Test_Language_Model_Token_Cursor_Terminate_Alternative_Recovery_Pass791.
- Updated README, parser coverage matrix, release checklist, and validation guards.

Scope note:
This improves structural grammar coverage for Ada select terminate alternatives. It is not compiler-grade tasking legality checking, terminate-alternative placement validation, selective-accept semantics, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
