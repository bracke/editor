Editor Phase 579 — IDE-grade outline/semantic language model — pass 356

This pass adds a conservative overload-selection API on top of the existing
scope-aware resolver.

Implemented:
- Added Editor.Ada_Symbol_Resolver.Resolve_Call_In_Scope.
- The resolver now filters retained same-name callable candidates by:
  * actual count,
  * positional actual type names,
  * named actual associations,
  * simple formal parameter type names,
  * expected function/operator result type when supplied.
- Ambiguous candidates remain in the returned Matches vector instead of being
  collapsed to the first declaration.
- Non-callable symbols are ignored by call overload selection.
- Existing Resolve_In_Scope behavior is preserved for ordinary identifier and
  selected-name lookup.
- Added AUnit regression coverage:
  * Test_Resolver_Call_Overload_Resolution_Uses_Profile_Actuals

Still intentionally conservative:
- This is not GNAT-equivalent overload legality checking.
- It does not evaluate expression types by itself; callers must provide a
  bounded actual-profile shape when available.
- It does not implement defaulted formal insertion, universal numeric rules,
  dispatching resolution, access-to-subprogram conversions, or full generic
  contract resolution.
- Ambiguous or incomplete cases remain ambiguous/unresolved rather than guessed.
