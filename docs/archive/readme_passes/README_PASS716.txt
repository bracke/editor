Editor Pass716
==========================

Focus: generic instantiation grammar depth.

This pass improves structural Ada token-cursor coverage for ordinary generic
instantiation declarations while preserving the existing language-model and
rendering invariants.

Implemented:

* Added instantiation-kind markers for package, procedure, and function
  instantiations.
* Added explicit positional generic actual association markers.
* Added explicit named association box markers for `Selector => <>`.
* Added nested generic actual-part and nested named-association markers for
  actual expressions containing call/instantiation-shaped association lists.
* Added generic actual recovery-boundary markers for trailing-comma and
  missing-close-parenthesis actual lists.
* Preserved existing generic actual and formal-package actual compatibility
  markers.
* Added AUnit regression coverage for package/procedure/function
  instantiations, positional and named actuals, operator selectors, nested
  associations, named boxes, and malformed actual-list recovery.
* Updated the phase language validation guard and user-facing docs.

This improves structural grammar coverage for Ada generic instantiations.  It
is not compiler-grade legality checking for generic contract matching, overload
resolution, visibility, actual conformance, box legality, elaboration, or
instance/body relationships.
