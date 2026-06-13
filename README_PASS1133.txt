Pass1133 - AST coverage integrated closure blockers

This pass turns the Pass1132 parser/AST semantic coverage audit into actionable semantic closure blockers.

Added:
- Editor.Ada_Integrated_Semantic_Closure.AST_Coverage
  - Build_With_AST_Coverage copies existing integrated closure contexts and appends coverage-audit rows.
  - Complete audit rows remain legal local closure rows.
  - Parser-node gaps, token-only parses, structural AST gaps, span gaps, metadata gaps, missing consumers, non-integrated consumers, and graceful-degradation-only rows become integrated semantic closure blockers.
  - Cross-unit metadata gaps are preserved as dependency failures so closure diagnostics distinguish missing semantic unit metadata from local parser/AST gaps.

Integrated closure extensions:
- Closure_Blocker_AST_Coverage
- Integrated_Closure_AST_Coverage_Blocker
- AST_Coverage_Error on Integrated_Closure_Context_Info

Diagnostic/provenance path:
- The semantic diagnostic feed source mapping recognizes AST coverage blockers.
- Diagnostic provenance labels AST coverage blockers distinctly.

Regression:
- Test_Ada_Integrated_Closure_AST_Coverage_Pass1133

This pass is not a UI/status/projection layer. It makes missing Ada 2022 parser/AST/metadata/consumer coverage participate in the same semantic closure path as the widened legality engines, preventing uncovered constructs from silently degrading compiler-grade analysis.
