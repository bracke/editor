Pass1183 - Accessibility master/scope final consumer legality

This pass adds Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality.

The pass closes the remaining hard accessibility consumer gaps by making exact master/scope, object-flow, discriminant/variant, and generic replay backmapping evidence mandatory for contexts that are easy to accept too early:

* anonymous access function results
* anonymous access parameters
* access discriminants
* allocators and allocator masters
* aggregate-contained access components
* access conversions
* return objects and return access values
* generic access actuals
* generic replay escape paths
* renamings
* controlled finalization paths
* private/full-view lifetime consistency
* cross-unit lifetime evidence

The package consumes:

* Editor.Ada_Accessibility_Scope_Consumer_Legality
* Editor.Ada_Object_Flow_Accessibility_Consumer_Legality
* Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality
* Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality

It classifies accepted rows, missing evidence, scope/object-flow/discriminant/generic-backmap blockers, anonymous access escapes, allocator/aggregate/access-discriminant master failures, access-conversion level failures, return-object/return-access lifetime failures, generic access escape failures, dangling renaming risks, finalization master failures, private/full-view lifetime failures, cross-unit lifetime blockers, representation/freezing blockers, coverage blockers, duplicate matching evidence, and indeterminate states.

AUnit coverage was added in Test_Ada_Accessibility_Master_Scope_Final_Consumer_Legality_Pass1183 and registered in tests/src/core_suite.adb.

This pass adds one compiler-grade building block for final accessibility master/scope consumer integration. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
