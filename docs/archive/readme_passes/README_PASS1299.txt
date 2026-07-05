Pass1299 implements Editor.Ada_Freezing_Representation_Vertical_Slice_Legality.

This is a vertical compiler-grade semantic slice rather than another closure,
provenance, search, or recheck layer.  It models concrete Ada freezing and
representation-clause legality over source-shaped type/freezing evidence.

The pass adds:

* real freezing-point order checks for representation and operational clauses;
* rejection of representation clauses that occur at or after the target is frozen;
* private/full-view barriers for full-view-sensitive clauses;
* generic formal and generic-template freezing barriers;
* inherited operational attribute conflict handling;
* limited/private-view stream attribute blockers;
* discriminant-dependent and variant-dependent record layout blockers;
* controlled/finalized component layout and address/size/alignment blockers;
* stale source/representation/clause fingerprint rejection;
* deterministic AUnit tests using source-shaped declaration and clause rows.

This pass reduces the concrete freezing/representation legality gap and avoids
adding UI/status/projection/remediation scaffolding.
