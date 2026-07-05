Pass1301 - Elaboration legality vertical slice

This pass adds Editor.Ada_Elaboration_Vertical_Slice_Legality.

It implements concrete Ada elaboration-rule evidence instead of another diagnostic,
provenance, remediation, or closure wrapper.  The pass builds source-shaped unit,
dependency, pragma, body-availability, and call evidence and validates calls made
during elaboration against real prerequisite state.

Covered checks include:

* call-before-body rejection when no Elaborate/Elaborate_All evidence exists;
* missing body detection for calls that require an elaborated body;
* dependency cycle detection;
* pragma Elaborate and Elaborate_All evidence;
* Preelaborate and Pure call restrictions;
* limited/private view barriers;
* generic body availability for instantiation-time calls;
* separate-body linkage checks;
* stale source and dependency fingerprint rejection.

The AUnit coverage uses source-shaped units, dependencies, pragmas, and calls,
not synthetic closure/recheck state transitions.
