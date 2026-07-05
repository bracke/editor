Pass1132 - Parser/AST semantic coverage audit

This pass adds Editor.Ada_AST_Semantic_Coverage_Audit, a compiler-grade audit layer for Ada 2022 grammar-to-semantic coverage.

The package records, per Ada construct and semantic consumer, whether the construct has:

- a parser node rather than token-only recognition,
- structural AST shape,
- source span preservation,
- name-binding metadata,
- type/staticness metadata,
- contract/aspect metadata,
- flow/dataflow metadata,
- representation/freezing metadata,
- cross-unit metadata,
- an enabled and integrated semantic legality consumer.

The audit covers constructs needed by the widened semantic legality layers, including aspects, representation and operational clauses, generic formals and instantiations, task/protected/select constructs, separate bodies, renamings, access definitions, allocators, returns, assignments, calls, conversions, aggregates, container/delta aggregates, reductions, quantified expressions, discriminants, variants, exception handlers, and raise expressions.

The audit is snapshot-owned and deterministic. It performs no parsing, file IO, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, or external tool invocation. It gives legality consumers a concrete way to reject or degrade missing parser/AST coverage instead of silently producing false positives or false negatives.

Added AUnit coverage:

- Test_Ada_AST_Semantic_Coverage_Audit_Pass1132

This pass adds one compiler-grade building block for parser/AST completeness feeding semantic legality. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
