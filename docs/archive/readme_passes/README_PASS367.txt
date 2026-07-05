Pass 367 — Generic semantic expansion

Implemented bounded generic semantic expansion for the Ada language-intelligence layer.

Changes:
- Added language-model storage for generic actual associations:
  - Generic_Actual_Info
  - Max_Generic_Actuals
  - Add_Generic_Actual
  - Generic_Actual_Count
  - Generic_Actual_At
- Projected syntax-tree Node_Generic_Actual_Association rows into the language model.
- Extended selected-name resolver behavior for generic package instantiations:
  - Inst.Child can expose Child declarations retained inside the generic template.
  - The resolver returns the template symbol id as the conservative expanded view.
- Added generic actual substitution during selected-call overload filtering:
  - formal type names are substituted with retained named or positional actuals.
  - expected result type filtering also substitutes generic formal result types.
- Added regression test:
  - Test_Resolver_Generic_Instance_Expansion_Uses_Actuals
- Updated release/static validation guards and docs.

Conservative boundaries:
- No full GNAT generic legality checking.
- No instance body cloning or persistent expanded symbol table.
- No generic contract legality model.
- Ambiguous or unresolved actual/formal mappings degrade rather than guessing.
