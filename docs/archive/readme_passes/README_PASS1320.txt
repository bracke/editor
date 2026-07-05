Pass1320: Generic body replay/substitution vertical slice

Adds Editor.Ada_Generic_Body_Replay_Substitution_Vertical_Slice_Legality.

This pass continues the vertical semantic-slice direction instead of adding another diagnostic/provenance/recheck wrapper. It models concrete generic body replay after actual matching:

- generic body availability
- formal-to-actual binding presence
- source-to-instance backmapping presence
- nested instantiation replay
- nested cycle rejection
- bounded nested replay depth
- private/limited/incomplete view barriers
- overload resolution blockers in replayed calls/operators
- formal/actual type and profile substitution mismatch
- visibility blockers
- freezing blockers
- representation blockers
- accessibility blockers
- predicate blockers
- dataflow blockers
- shared-state blockers
- source, substitution, and backmapping fingerprint freshness

The AUnit tests use source-shaped generic body replay scenarios, including calls, object declarations, nested instantiations, representation clauses, Global/Depends-style state effects, and stale source/substitution/backmapping evidence.
