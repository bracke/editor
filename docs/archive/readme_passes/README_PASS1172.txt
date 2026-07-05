Pass1172 - Integrated semantic closure semantic consumer-chain bridge

This pass adds Editor.Ada_Integrated_Semantic_Closure.Consumer_Chain.

The new bridge feeds the repaired/gated semantic consumer chain into integrated semantic closure by consuming Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality rows from Pass1171. It preserves direct blocker families for the Pass1163-Pass1171 chain instead of flattening generic replay representation contract-predicate-dataflow failures into an anonymous diagnostic status.

Accepted generic replay representation CPD rows become confident local closure rows. Non-legal rows are mapped back to their semantic closure families: overload, accessibility, contract, elaboration, representation/freezing, definite flow/dataflow, Refined_Global/Refined_Depends, coverage gates, indeterminate closure, or wide legality where the remaining failure is a tasking/replay legality blocker with no more precise closure family.

This is a compiler-grade semantic integration pass: later closure consumers can now see whether a replayed generic representation/freezing conclusion was blocked by read-before-write/object-state, Global/Depends, call propagation, coverage repair gates, tasking/protected effects, or representation/freezing replay failures.

Regression: Test_Ada_Integrated_Closure_Semantic_Consumer_Chain_Pass1172.
