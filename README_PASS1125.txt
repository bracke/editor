Pass1125 - Generic instance body semantic expansion

This pass adds one compiler-grade building block for generic instance body
analysis.  It connects instantiated generic body actual/formal substitutions to
the widened semantic legality layers added in the recent passes instead of
adding another UI/projection surface.

Implemented package:

- Editor.Ada_Generic_Instance_Body_Semantic_Expansion

The package classifies substituted generic body contexts against:

- instantiated-body substitution status,
- overload legality,
- accessibility/lifetime legality,
- contract/aspect legality,
- Global/Depends dataflow legality,
- definite-initialization flow legality,
- predicate/invariant use-site legality,
- representation/layout/stream integration legality.

It preserves context identity, substitution identity, formal/actual text,
source spans, source fingerprints, blocker counts, deterministic result rows,
status/kind/formal lookups, and model fingerprints.  Multiple independent
semantic blockers remain visible as a combined blocker row instead of being
silently collapsed into the first failure.

Added AUnit regression:

- Test_Ada_Generic_Instance_Body_Semantic_Expansion_Pass1125

The test verifies that substituted generic body contexts feed widened legality
results, that overload/accessibility/representation/view/multiple-blocker
failures remain distinct, and that formal/kind/status lookups remain bounded
and deterministic.

Full compiler-grade Ada analysis remains incomplete until the remaining Ada
legality, overload/type resolution, generic, representation/freezing,
accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure
layers are fully integrated.
