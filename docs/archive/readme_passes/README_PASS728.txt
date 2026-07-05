# Editor pass728 — Formal package actual resolver view

This pass deepens the formal package work from pass726 by feeding retained
formal package actual metadata into the selected-name resolver path.

## What changed

* `Generic_Target_Symbol` now treats `Symbol_Generic_Formal_Package` as a
  conservative generic-template view in addition to ordinary package
  instantiations.
* Selected lookup through a formal package such as `Maps.Get` can expose the
  retained child declaration from the referenced generic package template when
  the formal package target is known.
* Expression type inference now benefits from the existing generic-actual
  substitution path for formal package selected names, so a template result type
  such as `Element` can be reported as the retained formal package actual such
  as `Actual_Element`.
* Added regression coverage for the resolver/type-inference handoff:
  `Test_Language_Model_Formal_Package_Actuals_Feed_Resolver_View`.
* Updated the phase validation guard to require the formal-package resolver
  marker and regression.

## Non-goals

This remains bounded editor analysis.  It improves structural grammar/model
coverage and resolver metadata for formal packages, but it is not compiler-grade
formal package contract checking, generic conformance checking, overload legality
checking, or full generic semantic expansion.
