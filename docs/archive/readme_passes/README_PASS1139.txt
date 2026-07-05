Pass1139 - Predicate/invariant propagation legality

This pass adds Editor.Ada_Predicate_Invariant_Propagation_Legality.

The new package deepens predicate and invariant checking beyond local use-site
classification.  Pass1124 established whether a predicate or invariant is legal
at an assignment, return, conversion, aggregate, call actual, default, or generic
actual.  Pass1139 propagates those obligations across semantic edges so checks
are not lost when values move through calls, generic instances, derived types,
private/full views, visible state updates, and Global/Depends flow-effect graph
edges.

The model classifies:

* static predicate preservation,
* dynamic predicate propagation,
* invariant preservation,
* dynamic invariant propagation,
* generic formal/actual predicate propagation,
* derived-type inherited invariant propagation,
* private/full-view predicate or invariant propagation,
* flow-effect graph predicate/invariant preservation,
* missing call-chain checks,
* missing generic-actual checks,
* derived invariant gaps,
* private-view barriers and private/full-view mismatches,
* visible state updates that require invariant rechecks,
* state updates not covered by flow effects,
* linked predicate use-site errors,
* linked flow-effect graph errors,
* coverage-gate blockers.

It also provides deterministic counters, lookups by status/kind/subtype/object,
row identity, source spans, messages, source fingerprints, and model
fingerprints.

Regression coverage:

* Test_Ada_Predicate_Invariant_Propagation_Legality_Pass1139

This pass is a compiler-grade semantic integration building block.  It does not
add parser, rendering, command, keybinding, workspace, or diagnostic projection
layers.
