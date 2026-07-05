Pass1356 - RM Gap Burn-Down Pass 14: Master / Lifetime / Accessibility Closure

Implemented package:
  Editor.Ada_RM_Gap_Burn_Down_Pass1356

Implemented tests:
  Test_Ada_RM_Gap_Burn_Down_Pass1356

Registered in:
  tests/src/core_suite.adb

This pass burns down the master/lifetime/accessibility closure gap. It forces
access values, access-object assignments, access discriminants, anonymous access
parameters, return objects, returned aggregates, allocators, unchecked
deallocation, generic substitution, task/protected lifetimes, and controlled
finalization ownership to share one canonical master/lifetime result.

The pass distinguishes:
  * legal lifetime scenarios;
  * static accessibility and master-escape illegality;
  * legal-with-runtime-check accessibility/finalization scenarios;
  * indeterminate rows with missing master, lifetime, accessibility,
    return-object, allocator, generic-substitution, cross-unit, call, or effect
    evidence;
  * stale evidence and fingerprint mismatch blockers;
  * semantic consumer disagreement across diagnostics, semantic colouring,
    outline, navigation, hover/details, and build-diagnostic bridge paths.

Concrete source-shaped burn-down coverage includes:
  * access values escaping shorter-lived masters;
  * returned access values and longer-lived access-object assignments;
  * access discriminant and anonymous access master escapes;
  * return-object, limited-return-object, controlled-return-object, and returned
    aggregate component lifetime ownership;
  * allocator and unchecked-deallocation lifetime preservation;
  * generic substitution preserving lifetime classification;
  * task/protected masters not being collapsed into ordinary block masters;
  * normal-return, exception-propagation, task/abort finalization preservation;
  * aggregate/assignment, call-actual, control-flow/finalization, and
    accessibility-slice consumer agreement.

This continues the RM gap burn-down phase by connecting the existing access,
allocator, call-site, control-flow, tasking, finalization, aggregate,
assignment, and generic substitution slices through a single master/lifetime
closure model.
