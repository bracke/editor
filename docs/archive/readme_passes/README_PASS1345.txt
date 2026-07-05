Pass1345 - RM Gap Burn-Down Pass 3

Implemented Editor.Ada_RM_Gap_Burn_Down_Pass1345.

This pass burns down the context/library-unit/elaboration cross-slice gap.  It forces the context-clause, library-unit/subunit, cross-unit view, elaboration, remediation, precision, and semantic-consumer models to produce one canonical source-shaped legality result.

The pass covers:

- with, private with, limited with, use package, and use type context-clause legality
- duplicate with/use clause detection
- context target resolution and unit-name matching
- private-with placement legality
- private-child visibility barriers
- limited-with cycle acceptance only when only limited views are used
- rejection of full-view use through limited views
- nonlimited dependency-cycle rejection
- package/subprogram spec/body identity and completion checks
- body/spec kind and profile conformance
- duplicate body and missing completion rejection
- private child spec/body checks
- body stub and separate subunit matching
- separate subunit parent and nested-parent checks
- inherited context visibility for subunits
- cross-unit private/full/limited/incomplete/generic-formal view propagation
- Elaborate, Elaborate_All, Preelaborate, Pure, call-before-body, dependency-cycle, and generic-body-availability elaboration checks
- legal-with-runtime-elaboration-check preservation
- indeterminate private/limited/incomplete/generic-formal/missing-full-view/missing-cross-unit states
- remediation promotion to Covered
- balanced legal/illegal/runtime-check/indeterminate regression evidence
- canonical consumer agreement for diagnostics, outline, navigation, hover/detail, semantic colouring, and build-diagnostic bridge paths
- source, AST, unit, view, closure, elaboration, and consumer fingerprint freshness

Added AUnit coverage in Test_Ada_RM_Gap_Burn_Down_Pass1345 and registered it in Core_Suite.
