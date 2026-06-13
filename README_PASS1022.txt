Pass1022: cross-unit visibility integration

This pass adds one compiler-grade building block for Ada cross-unit semantic lookup.  It introduces Editor.Ada_Cross_Unit_Visibility, a deterministic projection over the existing project index and cross-unit closure model.

The new model records context dependencies from ordinary with clauses, limited with clauses, private with clauses, and context use package clauses as first-class visibility inputs.  It preserves source unit, clause name, target unit, target path, limited/private/use flags, candidate counts, status, and a deterministic fingerprint.

The pass adds lookup-facing APIs so semantic consumers can ask whether a named unit is visible from a source unit without reparsing files or mutating editor state.  Missing, ambiguous, limited-view, private-view, and use-package-visible dependencies remain explicit metadata for later diagnostics and name-resolution layers.

Added AUnit coverage:

* Test_Ada_Cross_Unit_Visibility_Integration_Pass1022

This pass does not claim complete cross-unit Ada legality.  Full compiler-grade Ada analysis remains incomplete until limited-with incomplete views, private-with visibility constraints, child/private-child visibility, body/spec semantic conformance, overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
