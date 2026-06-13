Pass 498 - Predicate/invariant operational property unification

Implemented another representation/operational completeness pass focused on assertion-like operational properties that should follow the same retained metadata and legality path whether written as aspects or attribute-definition clauses.

Changes:
- Added explicit retained representation/operational clause kinds for Static_Predicate, Dynamic_Predicate, Predicate_Failure, Type_Invariant, Type_Invariant'Class, Initial_Condition, and Default_Initial_Condition.
- Extended attribute-definition clause lowering so for T'Static_Predicate use ..., for T'Type_Invariant use ..., for T'Type_Invariant'Class use ..., and related clauses no longer remain generic/opaque representation items.
- Extended aspect lowering so with Static_Predicate => ..., with Dynamic_Predicate => ..., with Predicate_Failure => ..., with Type_Invariant => ..., with Type_Invariant'Class => ..., with Initial_Condition => ..., and with Default_Initial_Condition => ... use the same metadata path.
- Added shared target compatibility routing for type predicates/invariants/default initial conditions and package initial conditions.
- Reused mixed aspect/attribute-definition duplicate detection and required-expression diagnostics for these properties.
- Added regression coverage in Test_Language_Model_Predicate_Invariant_Operational_Unification_Pass.
