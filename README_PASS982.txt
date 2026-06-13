Editor Phase 579 pass982 — private-view visibility foundation

Implemented:
- Added Editor.Ada_Private_View_Visibility.
- Builds a deterministic model from parser-owned syntax-tree regions and Editor.Ada_Type_Graph.
- Records private partial type, full-view type, package spec region, matching package body region, private-part node/line, status, and fingerprint.
- Exposes View_Status_At_Line and Full_View_Visible_At_Line to distinguish visible-part partial views, private-part full views, and package-body full views.
- Added AUnit regression Test_Ada_Private_View_Visibility_Foundation_Pass982.

This pass adds one compiler-grade building block for private-view rules. Full compiler-grade Ada analysis remains incomplete until semantic consumers use this model throughout name resolution, expression typing, generic contracts, representation legality, freezing, and cross-unit semantic closure.
