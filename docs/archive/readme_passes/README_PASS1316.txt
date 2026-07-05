Pass1316 adds Editor.Ada_Selected_Name_Attribute_Vertical_Slice_Legality.

This is a vertical semantic slice, not a diagnostic/provenance/recheck wrapper.  It models concrete selected-name, expanded-name, component/reference, dereference, indexing, and attribute-reference legality needed by overload resolution, static expression evaluation, representation legality, accessibility/lifetime, and membership/case-choice consumers.

Coverage includes selected-name prefix/selector visibility, selector existence and ambiguity, entity-kind compatibility, private/limited/incomplete/generic-formal view barriers, attribute definition and prefix legality, static attribute requirements, attribute result compatibility, explicit/implicit dereference legality with null runtime-check handling, array/generalized indexing profile and dimension checks, component type compatibility, accessibility, representation, overload blockers, and source/AST/resolution/view fingerprint freshness.

AUnit coverage is in Test_Ada_Selected_Name_Attribute_Vertical_Slice_Legality_Pass1316 and uses source-shaped selected-name, attribute, dereference, indexing, generic-formal-view, and stale-evidence scenarios instead of synthetic closure-state transitions.
