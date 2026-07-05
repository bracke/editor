Pass1209 -- Final semantic stabilized closure legality

This pass adds Editor.Ada_Final_Semantic_Stabilized_Closure_Legality.

The package consumes Pass1208 final semantic stabilization gate rows and turns them
into first-class integrated-closure inputs.  Stable accepted rows become accepted
closure rows.  Stable withheld rows become explicit closure blockers preserving
the original prerequisite blocker family.  Changed and indeterminate rows remain
withheld instead of being exposed as confident current semantic conclusions.

The model preserves source node/span data, prerequisite depth, dependency depth,
source/application/convergence/stabilization fingerprints, deterministic closure
fingerprints, blocker-family counters, status/action queries, node queries, and
clear empty-model semantics.

The AUnit regression is
Test_Ada_Final_Semantic_Stabilized_Closure_Legality_Pass1209.
