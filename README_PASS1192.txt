Pass1192 — Flow / Contract Final Proof Legality

This pass adds Editor.Ada_Flow_Contract_Final_Proof_Legality.

It strengthens the compiler-grade Ada semantic model for Global, Depends, Refined_Global, Refined_Depends, abstract/refined state, volatile and atomic effects, independent components, call-chain propagation, generic effect substitution, and task/protected shared-state effects.

The pass consumes and preserves blockers from Refined_Global / Refined_Depends conformance, flow-refinement consumers, dataflow definite-initialization consumers, contract predicate/dataflow consumers, cross-unit final semantic closure, and representation/freezing final hard cases.

It classifies accepted final flow/contract proof rows only when the required consumer evidence is present. It preserves blocker families for missing refined conformance, missing flow consumer rows, missing initialization/dataflow rows, missing contract CPD rows, cross-unit blockers, representation blockers, transitive Depends gaps/cycles/overflow, dispatching Global refinement gaps, abstract/refined state errors, volatile ordering errors, atomic read/write errors, independent-component blockers, shared-state task/protected blockers, fingerprint mismatches, multiple blockers, and indeterminate proof states.

Added regression:
Test_Ada_Flow_Contract_Final_Proof_Legality_Pass1192
