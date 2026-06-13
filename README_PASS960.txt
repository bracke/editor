Editor Phase 579 - Semantic language-model pass960

This pass adds Editor.Ada_Static_Expressions, a compiler-grade static-expression staging layer. It evaluates a conservative deterministic subset of Ada static integer expressions from the parser-owned snapshot: integer literals, named-number/static-constant references, parentheses, unary signs, and +, -, *, /, mod, and rem. Unsupported or unresolved expressions remain explicitly non-static/unresolved instead of being guessed.

Regression added:
- Test_Ada_Static_Expression_Foundation_Pass960

Scope: this is a compiler-grade static-expression building block for later representation legality, range legality, generic matching, freezing diagnostics, and overload/type analysis. It does not yet complete full Ada static expression evaluation, real/universal numeric arithmetic, static attributes, enumeration positions, modular overflow rules, or cross-unit constant folding.
