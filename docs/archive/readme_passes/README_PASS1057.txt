Pass1057 — Ada expression diagnostics view-compatibility projection

This pass extends Editor.Ada_Expression_Diagnostics so private-view and limited-view compatibility barriers produced by Editor.Ada_View_Aware_Compatibility are projected into the normal expression diagnostic model.

Implemented building blocks:

* Adds Build_With_View_Compatibility, consuming an existing expression type model plus a view-aware compatibility model.
* Adds Build_With_Overload_Causes_And_View_Compatibility for combined overload-cause and view-aware diagnostic projection.
* Preserves view-aware diagnostic identity, view status, source expression/node, span, expected/actual subtype labels, cross-unit target/selector detail, source fingerprint, and deterministic diagnostic fingerprint.
* Projects private full-view-hidden, limited incomplete/full-view-hidden, cross-unit private, cross-unit unresolved, known incompatible, and indeterminate view compatibility cases into expression diagnostics.
* Keeps compatible view metadata non-diagnostic while still allowing Editor.Ada_View_Aware_Compatibility to expose it to later semantic consumers.
* Adds deterministic counters for view-aware diagnostics, private-view diagnostics, limited-view diagnostics, and unresolved view diagnostics.
* Adds AUnit regression coverage in Test_Ada_Expression_Diagnostics_View_Compatibility_Pass1057.

Invariant notes:

* No rendering-side parsing.
* No file saves or reloads during analysis.
* No dirty-state mutation.
* No command-palette, keybinding, workspace, or render mutation leaks.
* The new projection consumes snapshot-owned semantic models only.
