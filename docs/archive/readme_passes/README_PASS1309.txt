Pass1309 - Renaming/Alias vertical semantic legality

This pass adds Editor.Ada_Renaming_Alias_Vertical_Slice_Legality.

It is a vertical Ada semantic slice, not a diagnostic/provenance/recheck/closure wrapper.
It models concrete renaming and alias legality for source-shaped semantic rows:

* object, exception, package, subprogram, generic-unit, entry, and operator renamings;
* renamed target existence and visibility;
* renamed entity-kind compatibility;
* object type and mode compatibility, including universal numeric compatibility;
* constant-view versus variable-view restrictions;
* limited/private-view barriers;
* accessibility escape blockers through renamed objects and access values;
* subprogram and operator profile conformance;
* generic and package contract conformance;
* entry-family profile compatibility;
* alias-cycle and alias-depth overflow detection;
* predicate/runtime-check interaction;
* shared-state legality blockers;
* source, AST, and substitution fingerprint freshness.

Added AUnit coverage in Test_Ada_Renaming_Alias_Vertical_Slice_Legality_Pass1309 using source-shaped renaming contexts instead of synthetic closure-state rows.
