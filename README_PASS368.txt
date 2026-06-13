Pass 368 — generic instance expression inference completeness

Implemented another bounded generic semantic expansion pass for the Phase 579 Ada language-intelligence layer.

Changes:
- Fixed selected generic instance expansion ownership check in Editor.Ada_Symbol_Resolver so template children are matched against the resolved generic target symbol.
- Added effective expression-type inference for selected generic package instances:
  - Instance.Object now substitutes retained generic actuals for formal object subtype names.
  - Instance.Function now substitutes retained generic actuals for formal result types.
  - Nested expression-aware overload resolution uses the substituted effective type rather than the raw generic formal name.
- Preserved conservative behavior: unresolved or ambiguous generic instances still return no inferred type instead of acting as wildcard overload actuals.
- Added regression test:
  - Test_Resolver_Generic_Instance_Expression_Inference_Substitutes_Actuals
- Updated release/static validation guards and docs.

Conservative boundaries:
- No full GNAT generic legality checking.
- No instance body cloning or persistent expanded symbol table.
- No generic contract legality model.
- Ambiguous or unresolved actual/formal mappings degrade rather than guessing.
