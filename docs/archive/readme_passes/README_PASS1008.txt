Pass1008: expression target-name and update/delta inference

This pass adds one compiler-grade building block for Ada 2022 target-name and update-expression analysis. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution closure, complete expected-type propagation, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Implemented:
- Extended Editor.Ada_Expression_Types with Target_Name_Inference_Status.
- Target-name @ expressions now retain explicit context-required versus context-propagated metadata.
- Delta/update aggregates now retain expected subtype, source subtype, compatibility/mismatch/unknown counters, and update-count metadata.
- Added deterministic counters for target-name context propagation, context-required cases, compatible update expressions, mismatches, and unknown update expressions.
- Target-name/update metadata contributes to expression-type fingerprints.
- Added AUnit regression Test_Ada_Expression_Target_Name_Update_Inference_Pass1008.
