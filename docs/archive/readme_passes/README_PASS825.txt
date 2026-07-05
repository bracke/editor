Pass825 - Package declarative item recovery parity

Pass825 deepens Ada package declaration recovery metadata for malformed visible and private declarative items. Package declarations now distinguish recovery boundaries reached while scanning visible declarative items from those reached while scanning private declarative items, so malformed/in-progress declarations can be highlighted and recovered without flattening both sections into a shared package recovery marker.

Implementation notes:
- Added `Production_Package_Visible_Declarative_Item_Recovery_Boundary`.
- Added `Production_Package_Private_Declarative_Item_Recovery_Boundary`.
- Updated package declaration part scanning to pass visible/private-specific recovery productions into `Skip_Package_Declarative_Item`.
- Preserved existing visible/private part and declarative item metadata, package end-name metadata, and package end terminator recovery.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Pass825`.

Scope note: this improves structural grammar coverage for Ada package declaration visible/private declarative-item recovery. It is not compiler-grade declarative-item legality checking, visibility analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
