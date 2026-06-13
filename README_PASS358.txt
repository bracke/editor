Pass 358 — expression-aware overload resolution

Implemented:
- Added Editor.Ada_Symbol_Resolver.Infer_Expression_Type_In_Scope.
- Added Editor.Ada_Symbol_Resolver.Resolve_Call_Expression_In_Scope.
- Expression-aware call resolution now derives conservative actual type profiles from:
  * retained object/constant/generic-formal-object subtype metadata,
  * Boolean literals,
  * string literals,
  * character literals,
  * integer and real numeric literals as universal_integer/universal_real,
  * qualified expressions,
  * simple type conversions when the prefix resolves to a retained type/subtype,
  * enumeration literal parent symbols,
  * unique nested parameterless function/operator calls,
  * named actual associations,
  * expected result expressions.
- Unknown inferred actuals are encoded as non-matching placeholders instead of being treated as wildcard actual types.
- Expected-result expressions that cannot be inferred return no match instead of guessing.
- Resolve_Call_In_Scope now accepts universal_integer/universal_real actual-profile markers for common predefined numeric formal types.
- Added regression coverage: Test_Resolver_Expression_Aware_Overload_Resolution.

Still conservative:
- No GNAT-equivalent expression typing.
- No dispatching resolution.
- No access-to-subprogram conversion model.
- No generic contract expansion.
- No arbitrary static-expression evaluation.
- Ambiguous nested calls remain unresolved rather than guessed.
