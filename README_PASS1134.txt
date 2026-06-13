Pass1134 - Semantic coverage gates

This pass adds Editor.Ada_Semantic_Coverage_Gates.

The package consumes Pass1132 parser/AST semantic coverage audit rows and turns them into deterministic legality-safety gates.  A downstream semantic result can now be checked before it is treated as a confident Ada legality conclusion.  Complete coverage opens the gate; parser-node gaps, token-only parses, structural AST gaps, source-span gaps, name/type/staticness/contract/flow/representation metadata gaps, cross-unit metadata gaps, missing consumers, non-integrated consumers, graceful-degradation-only paths, and indeterminate construct coverage produce explicit gating actions.

The gating actions distinguish:

- allow confident result,
- degrade to indeterminate,
- suppress legal result,
- suppress derived result,
- require cross-unit closure,
- require parser/AST repair,
- require semantic metadata repair,
- require semantic consumer integration,
- block unsafe result.

This prevents widened legality packages from reporting a construct as legal when the underlying parser/AST/metadata/consumer coverage is incomplete.  It is a semantic correctness layer rather than a diagnostic projection or UI pass.

Regression added:

- Test_Ada_Semantic_Coverage_Gates_Pass1134

The pass remains deterministic, bounded, snapshot-owned, and non-mutating.  It introduces no rendering-side parsing, file save/reload path, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration.
