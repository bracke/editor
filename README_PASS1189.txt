Pass1189 - Overload/type final RM consumer legality

This pass adds Editor.Ada_Overload_Type_Final_RM_Consumer_Legality.

Purpose

Pass1189 closes another overload/type-resolution hard edge by feeding repaired access-definition AST evidence, overload/type edge precision evidence, and generic source/instance backmapping evidence into a final Ada RM overload/type consumer. It is a semantic legality pass, not a diagnostic/projection/status pass.

Coverage

The new layer covers:

- prefixed-call primitive visibility
- access-to-subprogram profile matching
- access-to-subprogram null-exclusion matching
- access-to-subprogram convention matching
- class-wide controlling-result interactions
- inherited/private-extension primitive hiding
- universal fixed/root numeric mixed-mode ties
- dispatching inherited operations
- generic formal subprogram instances
- nested generic prefixed calls

Confident legal conclusions are withheld when required overload/type edge rows, access-definition AST repair rows, generic source/instance backmapping rows, or cross-unit view evidence are missing, blocked, ambiguous, or indeterminate.

Regression

Added and registered:

- Test_Ada_Overload_Type_Final_RM_Consumer_Legality_Pass1189

The tests cover accepted final RM rows, ambiguity preservation, missing access AST evidence, missing generic backmapping evidence, and cross-unit view barriers.
