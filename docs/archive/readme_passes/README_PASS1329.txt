Pass1329 — Contract/aspect legality vertical slice

Implemented Editor.Ada_Contract_Aspect_Vertical_Slice_Legality.

This pass adds a concrete, source-shaped Ada contract/aspect legality engine for
Pre, Post, Type_Invariant, Static_Predicate, Dynamic_Predicate,
Default_Initial_Condition, Initial_Condition, Global, Depends,
Refined_Global, Refined_Depends, Abstract_State, Refined_State,
Preelaborable_Initialization, No_Return, Inline, and Convention.

The checker models target-kind legality, Boolean expression requirements,
staticness requirements, runtime assertion/predicate checks, Global mode
compatibility, Depends source/target presence, dependency cycles, abstract-state
refinement requirements, refined-state constituents, preelaborable
initialization blockers, No_Return fallthrough, convention/profile
compatibility, private/limited/incomplete/generic-formal view barriers, and
source/AST/type/profile/state/effect fingerprint freshness.

Added AUnit coverage in
Test_Ada_Contract_Aspect_Vertical_Slice_Legality_Pass1329 and registered it in
Core_Suite.
