pass 359 — expression-aware overload completeness

This pass extends the conservative expression-aware overload resolver added in
pass 358.  The resolver now infers types for a wider set of bounded expression
forms before filtering overload sets:

* parenthesized expressions, e.g. (Value)
* signed numeric literals, e.g. -1 and +16#10#
* top-level comparison expressions as Boolean when both operands have inferred
  types
* simple Boolean word-operator expressions when both operands infer Boolean
* top-level arithmetic/operator expressions by consulting retained quoted
  operator-function overloads and, when no user operator is retained, by using a
  conservative same-type/universal-numeric fallback

Unknown operands still do not become wildcard actuals.  If either side of an
operator expression cannot be inferred, expression-aware call resolution returns
no selected overload for that actual profile.

Regression coverage added:

* Test_Resolver_Expression_Aware_Operator_Expressions

Files changed:

* src/core/editor-ada_symbol_resolver.adb
* tests/src/editor-syntax_semantics-tests.adb
* README.md
* docs/outline.md
* docs/syntax_colouring.md
* docs/release/RELEASE_CHECKLIST.md
* tools/release_check.adb

No Python, shell scripts, generated parser tooling, or rendering-side parsing
were added.
