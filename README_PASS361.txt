Editor Phase 579 pass361

Completeness pass focus: expression-aware conditional-expression inference for conservative overload resolution.

Changes:
- Extended Editor.Ada_Symbol_Resolver.Infer_Expression_Type_In_Scope to recognize Ada conditional expressions of the form:
  if Condition then Then_Expression else Else_Expression
- Conditional expressions infer a result type only when:
  * the condition expression resolves to Boolean;
  * both branches infer a type; and
  * both branches are the same type or compatible through the existing universal-numeric fallback.
- Unknown conditions, unknown branches, and incompatible branches return no inferred type, so Resolve_Call_Expression_In_Scope still does not treat incomplete expressions as wildcard actuals.
- Added regression coverage: Test_Resolver_Expression_Aware_Conditional_Expressions.

Still conservative:
- No full Ada expression parser.
- No GNAT-equivalent conditional-expression legality checking.
- No expected-type propagation into conditional branches.
- No static evaluation of branch expressions.
