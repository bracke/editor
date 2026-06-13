Pass1304: Editor.Ada_Parser_AST_Coverage_Vertical_Slice_Legality

This pass adds a concrete vertical parser/AST coverage slice for Ada 2022 constructs that previously tended to be handled through coverage repair wrappers or token/degraded evidence.

Implemented package:
  src/core/editor-ada_parser_ast_coverage_vertical_slice_legality.ads
  src/core/editor-ada_parser_ast_coverage_vertical_slice_legality.adb

Test package:
  tests/src/test_ada_parser_ast_coverage_vertical_slice_legality_pass1304.ads
  tests/src/test_ada_parser_ast_coverage_vertical_slice_legality_pass1304.adb

The slice models source-shaped Ada 2022 constructs and validates that each construct has parser-owned AST nodes, stable source spans, required child links, type metadata, semantic-consumer integration, expected construct kind, and fresh source/AST fingerprints.

Covered construct families include quantified expressions, reduction expressions, delta aggregates, container aggregates, declare expressions, target-name/update-expression contexts, parallel loops, and generalized indexing.

This is intentionally not a diagnostic/provenance/search/recheck/stabilization pass. It adds a compiler-grade parser/AST coverage building block so real semantic consumers can reject token-only or degraded constructs before trusting legality results.
