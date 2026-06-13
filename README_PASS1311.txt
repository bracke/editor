Pass1311 implements Editor.Ada_Tagged_Dispatching_Vertical_Slice_Legality.

This is a vertical semantic pass, not another diagnostic/provenance/recheck loop.  It adds concrete legality modelling for tagged types, type extensions, private extensions, interfaces, primitive operations, overriding, inherited primitives, class-wide calls, dispatching calls, controlling operands, and controlling results.

The pass checks source-shaped semantic rows for:

* tagged versus untagged type declarations;
* parent type presence and taggedness for extensions;
* private/full-view and limited-view barriers;
* interface implementation and profile conformance;
* abstract primitive override requirements;
* concrete primitive availability;
* overriding-required and overriding-forbidden legality;
* inherited primitive visibility/hiding;
* dispatching target presence;
* controlling operand and controlling result compatibility;
* class-wide call compatibility;
* ambiguous dispatching candidate sets;
* unexpected non-dispatching/static call contexts;
* accessibility, generic contract, renaming, and exception/finalization blockers;
* source, AST, profile, and substitution fingerprint freshness.

Added AUnit coverage in Test_Ada_Tagged_Dispatching_Vertical_Slice_Legality_Pass1311.  The tests use source-shaped tagged declarations, extensions, interface implementation rows, primitive override rows, inherited primitive rows, dispatching calls, class-wide calls, controlling-result calls, and cross-consumer blocker rows rather than closure-state transitions.
