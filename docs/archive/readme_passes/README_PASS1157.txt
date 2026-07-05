Pass1157 - Elaboration contract-flow consumer legality

This pass adds one compiler-grade semantic integration point between the refined Global/Depends contract-flow chain and elaboration graph closure.

New package:
  Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality

Purpose:
  Elaboration-time calls, default expressions, aspect expressions, representation items, generic instances, task activation edges, and policy-sensitive elaboration edges must not remain confidently legal when the matching Global/Depends or Refined_Global/Refined_Depends flow contract result is still blocked.

Semantic coverage:
  * accepts elaboration edges only when both elaboration graph closure and contract-flow refinement are legal;
  * preserves base elaboration graph errors before considering contract-flow acceptance;
  * rejects elaboration conclusions when refined Global coverage is missing a read or write;
  * rejects elaboration conclusions when refined Global modes mismatch or contain extra items;
  * rejects elaboration conclusions when refined Depends edges are missing, extra, or mode-invalid;
  * rejects calls and generic instances with unpropagated call effects;
  * preserves repaired coverage feedback blockers and linked flow graph errors;
  * keeps indeterminate refined-flow conclusions indeterminate for elaboration consumers;
  * exposes deterministic counters, lookups, source identity, source/target unit identity, and stable fingerprints.

Regression:
  Test_Ada_Elaboration_Contract_Flow_Consumer_Legality_Pass1157

Files added:
  src/core/editor-ada_elaboration_contract_flow_consumer_legality.ads
  src/core/editor-ada_elaboration_contract_flow_consumer_legality.adb
  tests/src/test_ada_elaboration_contract_flow_consumer_legality_pass1157.ads
  tests/src/test_ada_elaboration_contract_flow_consumer_legality_pass1157.adb

Files updated:
  tests/src/core_suite.adb
  README.md
  ada_parser_coverage_matrix.md
  syntax_colouring_notes.md
  release_checklist.md
  strict_runtime_validation.md

This pass avoids diagnostic/projection/status churn. It deepens semantic checking by making refined flow-contract legality a direct consumer input to elaboration/call-order conclusions.
