Pass1124: Predicate / invariant use-site legality

This pass adds one compiler-grade building block for predicate and invariant enforcement at semantic use sites.

Implemented:

- Added Editor.Ada_Predicate_Invariant_Use_Site_Legality.
  - Consumes predicate/staticness metadata from Editor.Ada_Staticness_Range_Predicate_Legality.
  - Consumes linked assignment, return, conversion/access/aggregate, overload, and generic-instance legality statuses.
  - Classifies predicate and invariant checks at assignments, object initializations, returns, conversions, qualified expressions, record aggregates, array aggregates, call actuals, default expressions, generic actuals, discriminant defaults, and component defaults.
  - Distinguishes static predicate success, dynamic predicate check preservation, invariant preservation, dynamic invariant checks, static predicate failure, unresolved predicates, non-static predicates where static predicates are required, invariant violations, unresolved invariants, private-view invariant barriers, missing checks at each use-site family, linked semantic failures, universal numeric unresolved cases, cross-unit unresolved views, and indeterminate rows.
  - Provides deterministic counters, lookups, result sets, and fingerprints for status, kind, subtype, predicate errors, invariant errors, missing checks, linked errors, legal rows, error rows, and indeterminate rows.
- Added Test_Ada_Predicate_Invariant_Use_Site_Legality_Pass1124 and registered it in tests/src/core_suite.adb.

The regression validates that:

- assignment use sites accept statically satisfied predicates and preserved invariants,
- return use sites reject statically false predicates,
- conversion results must retain required dynamic predicate checks,
- aggregate results enforce type invariant metadata,
- call actuals preserve dynamic predicate checks after overload legality,
- generic actuals preserve unresolved predicate blockers,
- cross-unit unresolved views block predicate/invariant checking,
- subtype/kind/status lookups remain deterministic and bounded.

This pass is intentionally a widened semantic rule pass. It connects predicate/staticness, invariants, assignment/return/conversion/aggregate/call/generic legality, and cross-unit view state around actual Ada use-site checks instead of adding another projection/status layer.

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
