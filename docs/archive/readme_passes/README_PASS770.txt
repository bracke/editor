Editor pass770 — protected anonymous access profile depth

Implemented a bounded token-cursor grammar pass for anonymous access-to-subprogram protected profiles.

Changed:
- Added Production_Access_Protected_Subprogram_Definition.
- Added Production_Access_Protected_Procedure_Profile.
- Added Production_Access_Protected_Function_Profile.
- Tagged access protected procedure/function profiles distinctly while preserving the existing access-to-subprogram, parameter-profile, result-profile, null-exclusion, default, and constraint metadata.
- Added bounded recovery for dangling access protected forms that are not followed by procedure or function.
- Added AUnit regression Test_Language_Model_Token_Cursor_Anonymous_Access_Protected_Profile_Depth.
- Updated README, coverage matrix, release checklist, and validation guards.

This improves structural grammar coverage for protected anonymous access-to-subprogram profiles. It is not compiler-grade protected-operation legality checking, accessibility analysis, null-exclusion legality checking, profile conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
