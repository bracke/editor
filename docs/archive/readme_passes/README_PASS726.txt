# Editor pass726 — Formal package actual projection

This pass deepens Ada generic formal package grammar projection from the syntax
tree into the language model. It is a narrow parser/model pass over pass725 and
does not change the editor architecture.

## Parser / syntax tree / language model

Formal package declarations now retain their formal package actual part under the
formal package symbol, not only in token-cursor grammar:

* `with package P is new G (A => B, others => <>);`
* named formal selectors inside formal package actual associations
* `others => <>` association-level box defaults

Whole-part formal package boxes, `with package P is new G (<>);`, remain bounded
box metadata on the formal package declaration and are not projected as bogus
positional generic actuals.

This lets resolver/index/semantic-colouring consumers inspect named formal
package actual associations while preserving the existing distinction between a
formal package whole-box default and ordinary generic actual associations.

## Tests

Added AUnit coverage:

* `Test_Language_Model_Formal_Package_Actuals_Project_Into_Model`

The validation guard now requires the formal-package projection path and the new
language-model regression coverage.

## Scope

This improves structural grammar coverage for Ada formal package declarations
and formal package actual parts. It is not compiler-grade legality checking for
formal package contract matching, generic formal conformance, instance freezing,
visibility effects, or full generic semantic expansion.
