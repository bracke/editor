Pass1023: limited-with incomplete-view rules

This pass adds one compiler-grade building block for Ada cross-unit visibility.  It introduces Editor.Ada_Limited_View_Rules, a deterministic projection over the cross-unit visibility model that classifies limited-with dependencies as incomplete-view-only visibility.

The new model records source unit, target unit, target path, clause name, candidate count, full-view visibility, incomplete-view visibility, full-view-hidden status, use-clause allowance, and a deterministic fingerprint.  Ordinary with/use/private dependencies are retained as nonlimited/full-view-visible inputs, while missing, ambiguous, and overflow dependencies remain explicit metadata for later diagnostics.

The pass adds lookup-facing APIs so semantic consumers can reject full-view assumptions for units visible only through limited with clauses without reparsing files or mutating editor state.

Added AUnit coverage:

* Test_Ada_Limited_With_Incomplete_View_Rules_Pass1023

This pass does not claim complete cross-unit Ada legality.  Full compiler-grade Ada analysis remains incomplete until private-with visibility constraints, child/private-child visibility, body/spec semantic conformance, overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
