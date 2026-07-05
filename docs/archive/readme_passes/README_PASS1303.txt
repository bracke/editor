Pass1303 adds Editor.Ada_Abstract_State_Global_Depends_Vertical_Slice_Legality.

This is a vertical semantic slice rather than another integration, diagnostic,
provenance, remediation, recheck, or stabilization wrapper.  It models concrete
Ada abstract/refined-state and Global/Depends legality evidence over
source-shaped rows.

Implemented checks include:

* Abstract-state declaration identity and duplicate-state rejection.
* Global aspect state mode compatibility.
* Depends edge source/target presence and visibility.
* Depends cycle blockers.
* Refined_State aspect presence.
* Constituent presence, extra constituent, and constituent-mode mismatches.
* Invisible constituent/view barriers.
* Volatile read/write ordering evidence.
* Atomic mixed access evidence.
* Protected/shared-state write requirements.
* Source and state fingerprint freshness.

The AUnit coverage uses source-shaped operation, state, constituent, Global,
Depends, volatile/atomic, and shared-state rows.  It avoids pure closure-state
transition tests so the pass reduces a concrete compiler-grade Ada semantic gap.
