Pass1135 - Integrated semantic closure coverage gates

This pass connects Pass1134 semantic coverage gates to the integrated semantic
closure path.

Added:
- Editor.Ada_Integrated_Semantic_Closure.Coverage_Gates
- Closure_Blocker_Coverage_Gate
- Integrated_Closure_Coverage_Gate_Blocker
- Coverage_Gate_Error on integrated closure contexts
- Test_Ada_Integrated_Closure_Coverage_Gates_Pass1135

The bridge converts coverage-gate rows into closure rows.  Complete coverage
remains legal local closure.  Parser/AST repair requirements, semantic metadata
repair requirements, consumer-integration requirements, suppressed legal results,
and blocked unsafe results become first-class semantic closure blockers.  Gates
that require cross-unit closure are preserved as dependency failures, and gates
that degrade a conclusion become indeterminate closure rows.

This prevents widened semantic diagnostics from reporting confident legality
when the underlying Ada 2022 construct coverage is incomplete.
