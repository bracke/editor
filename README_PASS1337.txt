Pass1337 - End-to-end Ada semantic scenario audit

This pass starts the third integration/audit step after the vertical semantic
slices and the canonical model agreement audit.  It adds
Editor.Ada_End_To_End_Semantic_Scenario_Audit_Pass1337 and a focused AUnit
suite.

The pass deliberately audits realistic Ada semantic stories rather than adding
another isolated legality-slice family or diagnostic projection loop.  Each
story requires source-shaped evidence, parser-owned AST evidence, canonical
model agreement, stable semantic fingerprints, required vertical-slice results,
and consumption by the semantic path that would emit or suppress legality
blockers.

Covered end-to-end stories:

* package private type with full view, representation/freezing, aggregate
  initialization, assignment/conversion, accessibility, and predicate/runtime
  checks;
* generic package instantiation with formal type/object/subprogram evidence,
  contract aspects, body replay, aggregate actuals, assignment/conversion,
  overload resolution, and flow refinement;
* tagged extension implementing synchronized/interface operations with
  overriding, dispatching, contracts, callable profile conformance, overload
  agreement, flow/effect consumption, and class-wide conversion;
* context clauses, private child visibility, limited-with behaviour, package
  body/spec completion, body stubs, separate subunits, elaboration, imported /
  exported callables, and profile conformance;
* protected/synchronized interface operations, volatile/atomic shared state,
  Global/Depends-style effects, parallel iteration, callable profiles, and
  runtime checks;
* representation/interfacing interactions spanning record layout, enumeration
  representation, Convention/Import/Export, stream/external representation,
  callable profile conformance, and freezing state.

The AUnit tests verify ready source-shaped scenarios and blockers for missing
required slice results, stale or unconsumed slice results, non-source-shaped
synthetic stories, stale fingerprints, cross-unit staleness, generic
substitution loss, view disagreement, overload/profile disagreement,
flow/effect non-consumption, representation/freezing inconsistency, lost runtime
checks, and unstable blocker-family identity.
