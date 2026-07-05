Pass1295 - coverage-proven remaining RM edge AST repair legality

This pass adds Editor.Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality.

It consumes stabilized remaining RM edge search/provenance evidence from the Pass1294 search-index row shape.  A repair conclusion is accepted only when the stabilized search evidence is blocking downstream semantic trust, the blocker is a remaining-RM-edge blocker, the source/substitution fingerprints still match, and concrete coverage evidence proves a local parser/AST gap.

The pass models repair prerequisites for parser-node gaps, structural AST gaps, token-only parsing, missing source spans, missing semantic metadata, and missing consumer integration.  It preserves blocker-family identity for missing search evidence, non-blocking search evidence, non-remaining-edge blockers, missing coverage proof, missing local AST gaps, parser-node gaps, structural AST gaps, token-only parses, source-span gaps, metadata gaps, consumer-integration gaps, source/substitution fingerprint mismatches, multiple blockers, and indeterminate states.

Added AUnit test:
  Test_Ada_Remaining_RM_Edge_Coverage_Proven_AST_Repair_Legality_Pass1295

This pass adds one compiler-grade building block for parser/AST repair that is strictly coverage-proven by stabilized remaining RM edge blockers.  Full compiler-grade Ada analysis remains incomplete until the final RM integrated semantic closure consumes the stabilized RM-completion closure, direct-consumer closure, remaining-edge closure, coverage-proven repair rows, generic/shared-state closure, abstract/refined state, volatile/atomic/shared-state effects, and all overload/type, representation/freezing, tasking/protected, elaboration, accessibility, finalization, predicate, and dataflow consumers together.
