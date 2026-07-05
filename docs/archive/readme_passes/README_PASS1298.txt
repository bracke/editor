Pass1298 implements Editor.Ada_Generic_Contract_Body_Vertical_Slice_Legality.

This is the second vertical semantic slice after the overload-resolution pivot.  It
adds concrete generic contract/body legality instead of another diagnostic or
closure loop.

The pass models source-shaped generic instantiations with formal types, formal
objects, formal subprograms, formal packages, defaults, nested instantiations,
private-view barriers, body replay requirements, and substitution fingerprints.
It validates formal/actual kind matching, type-class compatibility, object mode
compatibility, formal subprogram profiles, formal package contracts, defaulted
formal objects, body availability, body replay acceptance, nested instantiation
cycles, and stale substitution fingerprints.

AUnit coverage exercises accepted generic contracts, nested instantiations,
defaulted formal objects, missing actuals, kind mismatches, profile mismatches,
package contract mismatches, private-view blockers, missing bodies, nested cycles,
substitution fingerprint blockers, and deterministic empty inputs.
