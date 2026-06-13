Pass1225 — Volatile/atomic representation consumer legality

This pass adds Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality.

The new layer connects volatile/atomic/shared-state legality to representation consumers that depend on it: volatile full-access objects, atomic object clauses, atomic record components, independent component clauses, record layout, representation clauses, stream attributes, operational attributes, protected shared-object representation, task shared-object representation, and shared-passive package layout.

It consumes volatile/atomic/shared-variable evidence, representation/freezing shared-state evidence, abstract/refined-state consumer evidence, and shared-state stabilized closure evidence before accepting representation-sensitive shared-state conclusions. It preserves blocker families for volatile/atomic shared state, representation/freezing, abstract-state consumers, stabilized closure, volatile full access, atomic components, independent components, stream attributes, operational attributes, protected/tasking representation, source fingerprint mismatches, multiple blockers, and indeterminate rows.

Added AUnit coverage in Test_Ada_Volatile_Atomic_Representation_Consumer_Legality_Pass1225 and registered it in the core suite.
