# Editor Phase 579 pass761 — semantic-colouring consumers for newer Ada metadata

Pass761 wires recently added parser/language-model metadata families into
`Editor.Syntax_Semantics.Build_Map_From_Analysis`, the parser-owned semantic
colouring seam.

Implemented:

* Context-clause names now contribute package-like semantic tokens.
* Declarative `use` package names contribute package-like semantic tokens.
* Declarative `use type` and `use all type` names contribute type-like semantic
  tokens.
* Generic formal type detail metadata contributes the existing `Generic_Formal`
  semantic token bucket.
* Callable profile parameter metadata contributes value-like parameter tokens.
* Pragma metadata contributes pragma-name tokens and conservative value-like
  target tokens.
* Representation/operational metadata contributes target names using resolved
  symbol kinds when available, and routes attribute/aspect/pragma source names to
  the existing Attribute, Aspect_Name, and Pragma_Name buckets.
* Existing executable-binding semantic colouring now treats raise, delay, and
  abort targets as conservative value-like syntax-role metadata when no target
  symbol is known.

Regression coverage:

* `Test_Syntax_Semantics_New_Metadata_Consumers_Pass761`

This improves semantic-colouring consumption of parser-owned metadata. It does
not add new Ada grammar recognition, render-side parsing, LSP integration,
compiler invocation, overload resolution, or compiler-grade legality checking.
