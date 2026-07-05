Pass1185 — Tasking/protected final effect legality

This pass adds Editor.Ada_Tasking_Protected_Final_Effects_Legality.

The new package closes hard tasking/protected effect checks after the richer Pass1168–1184 semantic-consumer chain.  Protected action reentrancy, protected visible-state mutation, protected function entry calls, barrier side effects, entry queue safety, accept body effect consistency, requeue target/open safety, requeue-with-abort safety, select alternative legality, abortable-part finalization safety, delay alternative staticness, terminate alternative legality, task activation, and task termination are now gated by final elaboration, tasking contract/predicate/dataflow, representation/freezing, accessibility master/scope, and discriminant/variant evidence.

The pass preserves direct blocker families for base tasking effects, elaboration, representation/freezing, accessibility/lifetime, discriminants/variants, predicate/invariant/dataflow, initialization/object-state, coverage, duplicates, missing dependent evidence, and indeterminate evidence.  Confident legal tasking/protected conclusions are only retained when all required dependent rows are present, unique, and accepted.

Added AUnit regression:
  Test_Ada_Tasking_Protected_Final_Effects_Legality_Pass1185

This pass adds one compiler-grade building block for final tasking/protected effect legality.  Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
