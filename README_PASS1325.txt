Pass1325 - Callable profile/conformance vertical slice

This pass adds Editor.Ada_Callable_Profile_Conformance_Vertical_Slice_Legality.

It is a concrete Ada semantic vertical slice, not a diagnostic/provenance/recheck
wrapper.  It models callable profile conformance for subprogram declarations and
bodies, renamings, overriding declarations, access-to-subprogram conversions,
generic formal subprogram actuals, entries, operators, and dispatching primitive
profiles.

Covered legality evidence includes callable/designator kind, arity and defaulted
formals, parameter mode conformance, formal/result type conformance, default
expression conformance, null-exclusion conformance, convention compatibility,
access-to-subprogram profile conformance, overriding conformance, renaming
conformance, generic formal subprogram conformance, private/limited/incomplete
and generic-formal view barriers, and stale source/profile/type fingerprints.

The AUnit test uses source-shaped callable/profile/check rows rather than
closure-state transitions.
