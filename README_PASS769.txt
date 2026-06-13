Editor Phase 579 pass769 — body declarative recovery depth

Changes:
- Added Production_Package_Body_Declarative_Recovery_Boundary.
- Added Production_Subprogram_Body_Declarative_Recovery_Boundary.
- Package-body declarative item skipping now emits body-specific recovery metadata when malformed items synchronize at strong declaration/private/begin/end boundaries.
- Subprogram-body declarative item skipping now emits body-specific recovery metadata when malformed items synchronize at begin/exception/end or the next strong declaration boundary.
- Added Test_Language_Model_Token_Cursor_Body_Declarative_Item_Recovery_Depth.
- Updated validation guards and documentation markers.

Scope:
This improves structural grammar coverage for package/subprogram body declarative recovery. It is not compiler-grade declaration legality checking, body/spec conformance checking, visibility analysis, elaboration analysis, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
