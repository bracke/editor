Editor  IDE-grade outline/semantic language model pass439

This pass strengthens Ada token-cursor grammar coverage for generic formal subprogram defaults.

Changes:
- Added Production_Formal_Subprogram_Default_Box.
- Added Production_Formal_Subprogram_Default_Null.
- Added Production_Formal_Subprogram_Default_Abstract.
- Added Production_Formal_Subprogram_Default_Name.
- Parsed generic formal subprogram default alternatives after `is` structurally instead of opaque-skipping to the semicolon.
- Added AUnit regression coverage for `is <>`, `is null`, `is abstract`, and default-name forms.
- Updated validation/release guards and docs.

Remaining boundary:
The parser retains Ada grammar shape only. It does not validate generic contract legality, conformance, dispatching legality, null-subprogram legality, abstract-subprogram legality, or default-name visibility.
