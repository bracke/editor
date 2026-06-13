Pass1162 - Accessibility scope graph consumer integration

This pass adds Editor.Ada_Accessibility_Scope_Consumer_Legality.

The new semantic layer consumes Editor.Ada_Accessibility_Scope_Graph_Legality and Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality so assignment, return, conversion/access, allocator, access-discriminant, renaming, generic replay, representation/freezing, record-layout, and finalization consumers cannot remain confidently legal when exact master/scope graph evidence is missing, blocked, or indeterminate.

The pass classifies legal consumer acceptance, missing scope graph rows, missing discriminant/generic representation rows, missing/too-short masters, unresolved dynamic levels, anonymous access parameter escape, allocator master failures, return object/access lifetime failures, access discriminant master failures, access conversion level errors, generic substitution master mismatches, dangling renaming risks, finalization master failures, linked scope graph blockers, discriminant/variant blockers, generic representation blockers, representation-flow blockers, and indeterminate consumer states.

AUnit coverage was added in Test_Ada_Accessibility_Scope_Consumer_Legality_Pass1162 and registered in tests/src/core_suite.adb.

This is a semantic-depth pass. It does not add UI, command, palette, keybinding, rendering, lifecycle, status, or diagnostic projection plumbing.
