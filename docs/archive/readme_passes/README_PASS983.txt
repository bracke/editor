Editor pass983

This pass adds private-view-aware subtype compatibility.

Implemented:
- Added `Private_View_For_Full` to `Editor.Ada_Private_View_Visibility`.
- Added `Effective_Type_At_Line` so consumers can obtain the partial or full effective type view for a context.
- Extended `Editor.Ada_Subtype_Compatibility` with `Check_With_Private_View`.
- Added statuses for private partial-view compatibility, private full-view compatibility, and hidden full-view cases.
- Added regression `Test_Ada_Private_View_Subtype_Compatibility_Pass983`.

This is one compiler-grade building block for private-view rules. Full compiler-grade Ada analysis still requires private-view-aware checks to be threaded through overload resolution, expression typing, generic contracts, representation legality, freezing, and cross-unit semantic closure.
