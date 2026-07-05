Pass1214 adds Editor.Ada_Representation_Shared_State_Final_Legality.

This pass connects final representation/freezing hard-case evidence with abstract/refined state, volatile/atomic/shared-variable legality, and overload shared-state RM edge evidence.  Representation clauses, operational attributes, stream attributes, shared record layouts, private/full-view freezing, generic formal freezing, protected object representation, and task object representation no longer remain confidently legal when their shared-state or abstract-state prerequisites are missing, blocked, stale, or fingerprint-mismatched.

The pass preserves distinct blockers for final representation/freezing evidence, volatile/atomic/shared-state evidence, abstract/refined-state evidence, overload shared-state evidence, volatile representation errors, atomic representation errors, independent component conflicts, shared record-layout conflicts, stream/operational attribute conflicts, private-view freezing, generic formal freezing, protected/task representation effects, source fingerprint mismatches, multiple blockers, and indeterminate states.

Added AUnit regression: Test_Ada_Representation_Shared_State_Final_Legality_Pass1214.
