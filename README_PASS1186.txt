Pass1186 - Cross-unit final semantic closure legality

This pass adds Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality.

Purpose:
- Extend cross-unit semantic closure across the widened legality engines and final-consumer chain.
- Preserve blocker families instead of flattening them into a generic dependency failure.
- Gate final cross-unit confidence on integrated closure, overload/type-edge precision, generic replay backmapping, discriminant/variant consumers, final accessibility master/scope evidence, final elaboration evidence, final tasking/protected effects, representation/freezing CPD evidence, contract/predicate/dataflow evidence, refined Global/Depends conformance, unit completion/order, renaming/alias/use visibility, and exception/finalization legality.

Implemented semantics:
- Accepted closure states for local, with/use, private/full-view, limited-view, child/private-child, separate-body, generic-instance, representation, elaboration, and tasking/protected final closure.
- Dependency blockers for missing, ambiguous, overflow, stale, limited-view, private-view, child visibility, and separate-body paths.
- Body/spec completion blockers and generic body/backmapping blockers.
- Representation target and representation/freezing blockers.
- Elaboration dependence blockers.
- Overload/type-edge and dispatching/inherited primitive blockers.
- Accessibility/lifetime and discriminant/variant blockers.
- Predicate/invariant, contract/dataflow, and Refined_Global/Depends blockers.
- Tasking/protected final-effect blockers.
- Exception/finalization and renaming/alias/visibility blockers.
- AST repair, coverage-gate, integrated-closure, multiple-blocker, and indeterminate closure states.

Added regression:
- Test_Ada_Cross_Unit_Final_Semantic_Closure_Legality_Pass1186

Updated:
- tests/src/core_suite.adb
- README_PASS1186.txt
- README.md
- ada_parser_coverage_matrix.md
- syntax_colouring_notes.md
- release_checklist.md
- strict_runtime_validation.md
- docs/ada_parser_coverage_matrix.md
- docs/syntax_colouring_notes.md
- docs/release_checklist.md
- docs/strict_runtime_validation.md
- docs/release/RELEASE_CHECKLIST.md
- docs/release/STRICT_RUNTIME_VALIDATION.md

This pass adds one compiler-grade building block for final cross-unit semantic closure. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
