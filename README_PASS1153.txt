Pass1153 - Refined Global / Depends conformance legality

This pass adds one compiler-grade building block for body/spec flow-contract conformance.

New package:
  Editor.Ada_Refined_Global_Depends_Conformance_Legality

Purpose:
  Consume explicit flow-effect graph rows and repaired coverage semantic feedback, then check whether body effects conform to spec-level Global / Depends contracts and body-level Refined_Global / Refined_Depends refinements.

Semantic coverage:
  - body read/write effects against spec Global modes
  - body read/write effects against Refined_Global coverage
  - extra Refined_Global items without body effects
  - Refined_Global mode mismatches against spec Global permissions
  - Refined_Depends edges with source/target mode checks
  - missing and extra Refined_Depends edges
  - call-effect propagation through body/spec flow contracts
  - linked flow-effect graph blockers
  - repaired coverage semantic feedback blockers before accepting a confident result

Regression:
  Test_Ada_Refined_Global_Depends_Conformance_Legality_Pass1153

This pass avoids projection/status churn. It adds semantic rule depth by connecting the existing flow-effect graph and repaired coverage feedback to concrete Ada Refined_Global / Refined_Depends conformance checks.
